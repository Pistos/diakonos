module Diakonos

  class Buffer
    COLUMNS_FOR_DIAGNOSTICS = 1  # width in characters

    attr_reader :top_line, :left_column

    def display
      after_soft_wrap_toggled

      @pen_down = false

      # Ensure highlight cache is valid up to @top_line - 1
      if @top_line > 0
        if @highlight_cache_valid_to < @top_line - 1
          rebuild_start = @highlight_cache_valid_to + 1
          restore_highlight_state(
            @highlight_cache_valid_to >= 0 ? @highlight_cache[@highlight_cache_valid_to] : nil
          )
          (rebuild_start..(@top_line - 1)).each do |i|
            print_line @lines[i].expand_tabs( @tab_size )
            @highlight_cache[i] = snapshot_highlight_state
          end
          @highlight_cache_valid_to = @top_line - 1
        end

        restore_highlight_state @highlight_cache[@top_line - 1]
      else
        restore_highlight_state nil
      end

      @pen_down = true

      visible_height = $diakonos.main_window_height
      y = paint_visible_buffer_rows(visible_height:)
      paint_empty_rows_below(start_y: y, visible_height:)

      paint_column_markers

      @win_line_numbers&.refresh
      @win_main.setpos( @last_screen_y, @last_screen_x )
      @win_main.refresh

      if @language != @original_language
        set_language( @original_language )
      end

      @time_last_viewed = Time.now
    end

    def find_opening_match(line, bos_allowed: true, match_close: true)
      open_index = line.length
      open_token_class = nil
      open_match_text = nil
      match = nil
      match_text = nil

      @token_regexps.each do |token_class, regexp|
        match = regexp.match(line)

        if match
          if match.length > 1
            index = match.begin 1
            match_text = match[ 1 ]
            whole_match_index = match.begin 0
          else
            whole_match_index = index = match.begin( 0 )
            match_text = match[ 0 ]
          end

          bos_condition = (
            ! regexp.uses_bos || (
              bos_allowed && (whole_match_index == 0)
            )
          )
          index_is_earlier = (index < open_index)
          can_be_closed = (! match_close || @close_token_regexps[token_class])

          if(
            bos_condition &&
            index_is_earlier &&
            can_be_closed
          )
            open_index = index
            open_token_class = token_class
            open_match_text = match_text
          end
        end
      end

      [open_index, open_token_class, open_match_text]
    end

    # Prints text to the screen, truncating where necessary.
    # Returns nil if the string is completely off-screen.
    # write_cursor_col is buffer-relative, not screen-relative.
    # When soft wrap is on, returns the string unchanged so curses can
    # auto-wrap it onto subsequent visual rows.
    def truncate_off_screen( string, write_cursor_col )
      if soft_wrap?
        retval = (string == "" ? nil : string)
      else
        retval = string

        # Truncate based on left edge of display area
        if write_cursor_col < @left_column
          retval = retval[ (@left_column - write_cursor_col).. ]
          write_cursor_col = @left_column
        end

        if retval && (
          # Truncate based on right edge of display area
          write_cursor_col + retval.length > @left_column + Curses.cols - 1
        )
          new_length = ( @left_column + Curses.cols - write_cursor_col )
          if new_length <= 0
            retval = nil
          else
            retval = retval[ 0...new_length ]
          end
        end

        retval = nil  if retval == ""
      end

      retval
    end

    def paint_marks( row )
      expanded_line = @lines[ row ].expand_tabs( @tab_size )
      base_y = @win_main.cury

      @text_marks
      .values
      .flatten
      .reverse_each do |text_mark|
        if text_mark
          range = paint_marks__range_of_mark_in_row(
            line_length: expanded_line.length,
            row:,
            text_mark:,
          )

          if range
            @win_main.attrset text_mark.formatting

            if soft_wrap?
              paint_mark_wrapped(
                base_y:,
                expanded_line:,
                from: range[ :from ],
                to: range[ :to ],
              )
            else
              paint_marks__paint(
                base_y:,
                expanded_line:,
                from: range[ :from ],
                to: range[ :to ],
              )
            end
          end
        end
      end
    end

    def paint_column_markers
      # TODO: column markers on wrapped lines.
      return  if soft_wrap?

      $diakonos.column_markers.each_value do |data|
        column = data[ :column ]
        next  if column.nil?
        next  if column > Curses.cols - @left_column || column - @left_column < 0

        num_lines_to_paint = [ $diakonos.main_window_height, @lines.size - @top_line ].min
        ( 0...num_lines_to_paint ).each do |row|
          @win_main.setpos( row, column - @left_column )
          @win_main.attrset data[ :format ]
          @win_main.addstr( @lines[ @top_line + row ][ column + @left_column ] || ' ' )
        end
      end
    end

    def print_string( string, formatting = ( @token_formats[ @continued_format_class ] || @default_formatting ) )
      return  if ! @pen_down
      return  if string.nil?

      @win_main.attrset formatting
      @win_main.addstr string
    end

    # This method assumes that the cursor has been set up already at
    # the left-most column of the correct on-screen row.
    # It merely unintelligently prints the characters on the current curses line,
    # refusing to print characters of the in-buffer line which are offscreen.
    def print_line( line )
      i = 0
      substr = nil

      while i < line.length
        substr = line[ i.. ]
        if @continued_format_class
          close_index, close_match_text = find_closing_match(
            substr,
            @close_token_regexps[@continued_format_class],
            bos_allowed: i == 0
          )

          if close_match_text.nil?
            print_string truncate_off_screen( substr, i )
            print_padding_from( line.length )
            i = line.length
          else
            end_index = close_index + close_match_text.length
            print_string truncate_off_screen( substr[ 0...end_index ], i )
            @continued_format_class = nil
            i += end_index
          end
        else
          first_index, first_token_class, first_word = find_opening_match(
            substr,
            bos_allowed: i == 0,
            match_close: false
          )

          if @lang_stack.any?
            prev_lang, close_token_class = @lang_stack[-1]
            close_index, close_match_text = find_closing_match(
              substr,
              $diakonos.close_token_regexps[prev_lang][close_token_class],
              bos_allowed: i == 0
            )

            if close_match_text && close_index <= first_index
              # Print any remaining text in the embedded language
              s = substr[0...close_index]
              print_string( truncate_off_screen(s, i) )
              i += s.length

              @lang_stack.pop
              set_language prev_lang

              print_string(
                truncate_off_screen(
                  substr[
                    close_index...(close_index + close_match_text.length)
                  ],
                  i
                ),
                @token_formats[close_token_class]
              )
              i += close_match_text.length

              # Continue printing from here.
              next
            end
          end

          if first_word
            if first_index > 0
              # Print any preceding text in the default format
              print_string truncate_off_screen( substr[ 0...first_index ], i )
              i += substr[ 0...first_index ].length
            end

            print_string( truncate_off_screen( first_word, i ), @token_formats[ first_token_class ] )
            i += first_word.length

            if @close_token_regexps[first_token_class]
              change_to = @settings["lang.#{@language}.tokens.#{first_token_class}.change_to"]
              if change_to
                @lang_stack.push [ @language, first_token_class ]
                set_language change_to
              else
                @continued_format_class = first_token_class
              end
            end
          else
            print_string truncate_off_screen( substr, i )
            i += substr.length
            break
          end
        end
      end

      print_padding_from i
    end

    def print_padding_from( col )
      return  if ! @pen_down

      if soft_wrap?
        # After auto-wrap, the cursor is somewhere on the last visual row of
        # this buffer line. Pad from there to the right edge of that visual
        # row, regardless of how many wraps happened.
        remainder = wrap_width - @win_main.curx
      elsif col < @left_column
        remainder = Curses.cols
      else
        remainder = @left_column + Curses.cols - col
      end

      if remainder > 0
        print_string( " " * remainder )
      end
    end

    private def find_closing_match(line_segment, regexp, bos_allowed: true)
      close_match_text = nil
      close_index = nil

      line_segment.scan(regexp) do
        match = Regexp.last_match
        if match.length > 1
          index = match.begin 1
          match_text = match[1]
        else
          index = match.begin 0
          match_text = match[0]
        end
        if ( ! regexp.uses_bos ) || ( bos_allowed && ( index == 0 ) )
          close_index = index
          close_match_text = match_text
          break
        end
      end

      [close_index, close_match_text]
    end

    private def paint_continuation_gutter_rows(segments:, start_y:, visible_height:)
      blank_width = @settings[ 'view.line_numbers.width' ] + COLUMNS_FOR_DIAGNOSTICS

      ( 1...segments ).each do |seg_offset|
        cont_y = start_y + seg_offset
        if cont_y < visible_height
          @win_line_numbers.setpos( cont_y, 0 )
          @win_line_numbers.attrset @settings[ 'view.line_numbers.format' ]
          @win_line_numbers.addstr( ' ' * blank_width )
        end
      end
    end

    private def paint_empty_rows_below(start_y:, visible_height:)
      blank_width = @settings[ 'view.line_numbers.width' ] + COLUMNS_FOR_DIAGNOSTICS

      (start_y...visible_height).each do |y|
        if @win_line_numbers
          @win_line_numbers.setpos( y, 0 )
          @win_line_numbers.attrset @settings[ 'view.line_numbers.format' ]
          @win_line_numbers.addstr( ' ' * blank_width )
        end

        @win_main.setpos( y, 0 )
        @win_main.attrset @default_formatting
        linestr = " " * Curses.cols
        if @settings["view.nonfilelines.visible"]
          linestr[0] = @settings["view.nonfilelines.character"] || "~"
        end

        @win_main.addstr linestr
      end
    end

    private def paint_first_segment_gutter(buffer_row:, y:)
      @win_line_numbers.setpos( y, 0 )
      @win_line_numbers.attrset @settings[ 'view.line_numbers.format' ]
      n = ( buffer_row + 1 ).to_s
      @win_line_numbers.addstr(
        @settings[ 'view.line_numbers.number_format' ] % [
          n[ -[ @settings[ 'view.line_numbers.width' ], n.length ].min.. ],
        ]
      )

      if diagnostics_for_line( line: buffer_row ).any?
        @win_line_numbers.addstr( @settings[ 'view.line_numbers.diagnostic_marker' ] || '●' )
      else
        @win_line_numbers.addstr( ' ' )
      end
    end

    private def paint_line_number_gutter(buffer_row:, segments:, visible_height:, y:)
      paint_first_segment_gutter(buffer_row:, y:)

      paint_continuation_gutter_rows(
        segments:,
        start_y: y,
        visible_height:,
      )
    end

    # Paint a mark's range across the visual segments of a soft-wrapped row.
    # The row's first visual segment is at +base_y+; later segments follow on
    # subsequent screen rows.
    private def paint_mark_wrapped(base_y:, expanded_line:, from:, to:)
      if from < to
        first_segment = visual_segment_index( from )
        last_segment = visual_segment_index( to - 1 )

        (first_segment..last_segment).each do |segment|
          segment_from = [ from, segment * wrap_width ].max
          segment_to = [ to, (segment + 1) * wrap_width ].min
          screen_y = base_y + segment

          if segment_from < segment_to && screen_y < $diakonos.main_window_height
            @win_main.setpos( screen_y, visual_x_of( segment_from ) )

            @win_main.addstr expanded_line[ segment_from...segment_to ]
          end
        end
      end
    end

    # Paint a single buffer row's portion of a mark when soft wrap is off:
    # one screen row at +base_y+, clipped to the horizontally-scrolled view.
    private def paint_marks__paint(base_y:, expanded_line:, from:, to:)
      visible_from = [ from, @left_column ].max
      visible_to = [ to, @left_column + Curses.cols ].min

      if visible_from < visible_to
        @win_main.setpos( base_y, visible_from - @left_column )

        @win_main.addstr expanded_line[ visible_from...visible_to ]
      end
    end

    # The highlighted range, in expanded-column space, that +text_mark+
    # contributes to buffer +row+. Returns nil when +row+ falls outside the
    # mark. +line_length+ is the expanded length of the row's text.
    private def paint_marks__range_of_mark_in_row(line_length:, row:, text_mark:)
      range = nil

      case @selection_mode
      when :normal
        if text_mark.start_row < row && row < text_mark.end_row
          range = {
            from: 0,
            to: line_length,
          }
        elsif row == text_mark.start_row && row == text_mark.end_row
          range = {
            from: tab_expanded_column( text_mark.start_col, row ),
            to: tab_expanded_column( text_mark.end_col, row ),
          }
        elsif row == text_mark.start_row
          range = {
            from: tab_expanded_column( text_mark.start_col, row ),
            to: line_length,
          }
        elsif row == text_mark.end_row
          range = {
            from: 0,
            to: tab_expanded_column( text_mark.end_col, row ),
          }
        end
      when :block
        if(
          text_mark.start_row <= row && row <= text_mark.end_row ||
          text_mark.end_row <= row && row <= text_mark.start_row
        )
          range = {
            from: tab_expanded_column( text_mark.start_col, row ),
            to: tab_expanded_column( text_mark.end_col, row ),
          }
        end
      end

      range
    end

    # Draws each on-screen buffer row, advancing visual y by
    # num_visual_segments_for(row) so wrapped lines occupy multiple rows.
    # Returns the visual y just past the last drawn row.
    private def paint_visible_buffer_rows(visible_height:)
      y = 0
      buffer_row_offset = 0

      while(
        y < visible_height &&
        (@top_line + buffer_row_offset) < @lines.length
      )
        line_index = @top_line + buffer_row_offset
        segments = num_visual_segments_for( line_index )

        if @win_line_numbers
          paint_line_number_gutter(
            buffer_row: line_index,
            segments:,
            visible_height:,
            y:,
          )
        end

        @win_main.setpos( y, 0 )
        print_line @lines[ line_index ].expand_tabs( @tab_size )

        @highlight_cache[ line_index ] = snapshot_highlight_state
        if line_index > @highlight_cache_valid_to
          @highlight_cache_valid_to = line_index
        end

        @win_main.setpos( y, 0 )
        paint_marks line_index

        y += segments
        buffer_row_offset += 1
      end

      y
    end

  end

end
