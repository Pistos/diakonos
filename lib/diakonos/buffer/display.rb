module Diakonos

  class Buffer

    def find_opening_match( line, match_close = true, bos_allowed = true )
      open_index = line.length
      open_token_class = nil
      open_match_text = nil
      match = nil
      match_text = nil
      @token_regexps.each do |token_class,regexp|
        if match = regexp.match( line )
          if match.length > 1
            index = match.begin 1
            match_text = match[ 1 ]
            whole_match_index = match.begin 0
          else
            whole_match_index = index = match.begin( 0 )
            match_text = match[ 0 ]
          end
          if ( not regexp.uses_bos ) or ( bos_allowed and ( whole_match_index == 0 ) )
            if index < open_index
              if ( ( not match_close ) or @close_token_regexps[ token_class ] )
                open_index = index
                open_token_class = token_class
                open_match_text = match_text
              end
            end
          end
        end
      end

      [ open_index, open_token_class, open_match_text ]
    end

    def find_closing_match( line_, regexp, bos_allowed = true, start_at = 0 )
      close_match_text = nil
      close_index = nil
      if start_at > 0
        line = line_[ start_at..-1 ]
      else
        line = line_
      end
      line.scan( regexp ) do |m|
        match = Regexp.last_match
        if match.length > 1
          index = match.begin 1
          match_text = match[ 1 ]
        else
          index = match.begin 0
          match_text = match[ 0 ]
        end
        if ( not regexp.uses_bos ) or ( bos_allowed and ( index == 0 ) )
          close_index = index
          close_match_text = match_text
          break
        end
      end

      [ close_index, close_match_text ]
    end

    # Prints text to the screen, truncating where necessary.
    # Returns nil if the string is completely off-screen.
    # write_cursor_col is buffer-relative, not screen-relative
    def truncate_off_screen( string, write_cursor_col )
      retval = string

      # Truncate based on left edge of display area
      if write_cursor_col < @left_column
        retval = retval[ (@left_column - write_cursor_col)..-1 ]
        write_cursor_col = @left_column
      end

      if retval
        # Truncate based on right edge of display area
        if write_cursor_col + retval.length > @left_column + Curses::cols - 1
          new_length = ( @left_column + Curses::cols - write_cursor_col )
          if new_length <= 0
            retval = nil
          else
            retval = retval[ 0...new_length ]
          end
        end
      end

      retval == "" ? nil : retval
    end

    # Worker function for painting only part of a row.
    def paint_single_row_mark( row, text_mark, string, curx, cury )
      expanded_col = tab_expanded_column( text_mark.start_col, row )
      if expanded_col < @left_column + Curses::cols
        left = [ expanded_col - @left_column, 0 ].max
        right = tab_expanded_column( text_mark.end_col, row ) - @left_column
        if left < right
          @win_main.setpos( cury, curx + left )
          @win_main.addstr string[ left...right ]
        end
      end
    end

    def paint_marks( row )
      string = @lines[ row ][ @left_column ... @left_column + Curses::cols ]
      return  if string.nil? or string == ""
      string = string.expand_tabs( @tab_size )
      cury = @win_main.cury
      curx = @win_main.curx

      @text_marks.reverse_each do |text_mark|
        next  if text_mark.nil?

        @win_main.attrset text_mark.formatting

        case @selection_mode
        when :normal
          if ( (text_mark.start_row + 1) .. (text_mark.end_row - 1) ) === row
            @win_main.setpos( cury, curx )
            @win_main.addstr string
          elsif row == text_mark.start_row and row == text_mark.end_row
            paint_single_row_mark( row, text_mark, string, curx, cury )
          elsif row == text_mark.start_row
            expanded_col = tab_expanded_column( text_mark.start_col, row )
            if expanded_col < @left_column + Curses::cols
              left = [ expanded_col - @left_column, 0 ].max
              @win_main.setpos( cury, curx + left )
              @win_main.addstr string[ left..-1 ]
            end
          elsif row == text_mark.end_row
            right = tab_expanded_column( text_mark.end_col, row ) - @left_column
            @win_main.setpos( cury, curx )
            @win_main.addstr string[ 0...right ]
          else
            # This row not in selection.
          end
        when :block
          if(
            text_mark.start_row <= row && row <= text_mark.end_row ||
            text_mark.end_row <= row && row <= text_mark.start_row
          )
            paint_single_row_mark( row, text_mark, string, curx, cury )
          end
        end
      end
    end

    def paint_column_markers
      @diakonos.column_markers.each_value do |data|
        column = data[ :column ]
        next  if column.nil?
        next  if column > Curses::cols - @left_column || column - @left_column < 0

        ( 0...@diakonos.main_window_height ).each do |row|
          @win_main.setpos( row, column - @left_column )
          @win_main.attrset data[ :format ]
          @win_main.addstr( @lines[ @top_line + row ][ column + @left_column ] || ' ' )
        end
      end
    end

    def print_string( string, formatting = ( @token_formats[ @continued_format_class ] or @default_formatting ) )
      return  if not @pen_down
      return  if string.nil?

      @win_main.attrset formatting
      @win_main.addstr string
    end

    # This method assumes that the cursor has been setup already at
    # the left-most column of the correct on-screen row.
    # It merely unintelligently prints the characters on the current curses line,
    # refusing to print characters of the in-buffer line which are offscreen.
    def print_line( line )
      i = 0
      substr = nil
      index = nil
      while i < line.length
        substr = line[ i..-1 ]
        if @continued_format_class
          close_index, close_match_text = find_closing_match( substr, @close_token_regexps[ @continued_format_class ], i == 0 )

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
          first_index, first_token_class, first_word = find_opening_match( substr, MATCH_ANY, i == 0 )

          if @lang_stack.length > 0
            prev_lang, close_token_class = @lang_stack[ -1 ]
            close_index, close_match_text = find_closing_match( substr, @diakonos.close_token_regexps[ prev_lang ][ close_token_class ], i == 0 )
            if close_match_text and close_index <= first_index
              if close_index > 0
                # Print any remaining text in the embedded language
                print_string truncate_off_screen( substr[ 0...close_index ], i )
                i += substr[ 0...close_index ].length
              end

              @lang_stack.pop
              set_language prev_lang

              print_string(
                truncate_off_screen( substr[ close_index...(close_index + close_match_text.length) ], i ),
                @token_formats[ close_token_class ]
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
            if @close_token_regexps[ first_token_class ]
              if change_to = @settings[ "lang.#{@language}.tokens.#{first_token_class}.change_to" ]
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
      return  if not @pen_down

      if col < @left_column
        remainder = Curses::cols
      else
        remainder = @left_column + Curses::cols - col
      end

      if remainder > 0
        print_string( " " * remainder )
      end
    end

    def display
      return  if @diakonos.testing
      return  if ! @diakonos.do_display

      Thread.new do

        if @diakonos.display_mutex.try_lock
          begin
            Curses::curs_set 0

            @continued_format_class = nil

            @pen_down = true

            # First, we have to "draw" off-screen, in order to check for opening of
            # multi-line highlights.

            # So, first look backwards from the @top_line to find the first opening
            # regexp match, if any.
            index = @top_line - 1
            @lines[ [ 0, @top_line - @settings[ "view.lookback" ] ].max...@top_line ].reverse_each do |line|
              open_index = -1
              open_token_class = nil
              open_match_text = nil

              open_index, open_token_class, open_match_text = find_opening_match( line )

              if open_token_class
                @pen_down = false
                @lines[ index...@top_line ].each do |line|
                  print_line line
                end
                @pen_down = true

                break
              end

              index = index - 1
            end

            # Draw each on-screen line.
            y = 0
            @lines[ @top_line...(@diakonos.main_window_height + @top_line) ].each_with_index do |line, row|
              if @win_line_numbers
                @win_line_numbers.setpos( y, 0 )
                @win_line_numbers.attrset @settings[ 'view.line_numbers.format' ]
                n = ( @top_line+row+1 ).to_s
                @win_line_numbers.addstr(
                  @settings[ 'view.line_numbers.number_format' ] % [
                    n[ -[ @settings[ 'view.line_numbers.width' ], n.length ].min..-1 ]
                  ]
                )
              end
              @win_main.setpos( y, 0 )
              print_line line.expand_tabs( @tab_size )
              @win_main.setpos( y, 0 )
              paint_marks @top_line + row
              y += 1
            end

            # Paint the empty space below the file if the file is too short to fit in one screen.
            ( y...@diakonos.main_window_height ).each do |y|
              @win_main.setpos( y, 0 )
              @win_main.attrset @default_formatting
              linestr = " " * Curses::cols
              if @settings[ "view.nonfilelines.visible" ]
                linestr[ 0 ] = ( @settings[ "view.nonfilelines.character" ] or "~" )
              end

              @win_main.addstr linestr
            end

            paint_column_markers

            if @win_line_numbers
              @win_line_numbers.refresh
            end
            @win_main.setpos( @last_screen_y , @last_screen_x )
            @win_main.refresh

            if @language != @original_language
              set_language( @original_language )
            end

            Curses::curs_set 1
          rescue Exception => e
            @diakonos.log( "Display Exception:" )
            @diakonos.log( e.message )
            @diakonos.log( e.backtrace.join( "\n" ) )
            show_exception e
          end

          @diakonos.display_mutex.unlock
          @diakonos.display_dequeue
        else
          @diakonos.display_enqueue( self )
        end

      end

    end

  end

end