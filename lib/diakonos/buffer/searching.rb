module Diakonos

  class Buffer

    CHARACTER_PAIRS = {
      '(' => { partner: ')', direction: :forward },
      '<' => { partner: '>', direction: :forward },
      '{' => { partner: '}', direction: :forward },
      '[' => { partner: ']', direction: :forward },
      ')' => { partner: '(', direction: :backward },
      '>' => { partner: '<', direction: :backward },
      '}' => { partner: '{', direction: :backward },
      ']' => { partner: '[', direction: :backward },
    }

    attr_accessor :search_area

    def establish_finding( regexps, search_area, from_row, from_col, match )
      found_text = match[ 0 ]
      finding = Finding.new( from_row, from_col, from_row, from_col + found_text.length )
      if finding.match( regexps, @lines )
        if(
          search_area.contains?( finding.start_row, finding.start_col ) &&
          search_area.contains?( finding.end_row, finding.end_col - 1 )
        )
          throw :found, finding
        end
      end
    end

    # Takes an array of Regexps, which represents a user-provided regexp,
    # split across newline characters.  Once the first element is found,
    # each successive element must match against lines following the first
    # element.
    def find( regexps, options = {} )
      return  if regexps.nil?
      regexp = regexps[ 0 ]
      return  if regexp.nil? || regexp == //

      direction          = options[ :direction ]
      replacement        = options[ :replacement ]
      auto_choice        = options[ :auto_choice ]
      from_row           = options[ :starting_row ] || @last_row
      from_col           = options[ :starting_col ] || @last_col
      show_context_after = options[ :show_context_after ]

      search_area = @search_area || TextMark.new( 0, 0, @lines.size - 1, @lines[ -1 ].size, nil )

      if ! search_area.contains?( from_row, from_col )
        from_row, from_col = search_area.start_row, search_area.start_col
      end

      if direction == :opposite
        case @last_search_direction
        when :up
          direction = :down
        else
          direction = :up
        end
      end
      @last_search_regexps = regexps
      @last_search_direction = direction

      wrapped = false
      match = nil

      finding = catch :found do

        if direction == :down

          # Check the current row first.

          index = @lines[ from_row ].index(
            regexp,
            ( @last_finding ? @last_finding.start_col : from_col ) + 1
          )
          if index
            establish_finding( regexps, search_area, from_row, index, Regexp.last_match )
          end

          # Check below the cursor.

          ( (from_row + 1)..search_area.end_row ).each do |i|
            line = @lines[ i ]
            if i == search_area.end_row
              line = line[ 0...search_area.end_col ]
            end
            index = line.index( regexp )
            if index
              establish_finding( regexps, search_area, i, index, Regexp.last_match )
            end
          end

          if index
            establish_finding( regexps, search_area, search_area.end_row, index, Regexp.last_match )
          end

          # Wrap around.

          wrapped = true

          index = @lines[ search_area.start_row ].index( regexp, search_area.start_col )
          if index
            establish_finding( regexps, search_area, search_area.start_row, index, Regexp.last_match )
          end

          ( search_area.start_row+1...from_row ).each do |i|
            index = @lines[ i ].index( regexp )
            if index
              establish_finding( regexps, search_area, i, index, Regexp.last_match )
            end
          end

          # And finally, the other side of the current row.

          if from_row == search_area.start_row
            index_col = search_area.start_col
          else
            index_col = 0
          end
          if index = @lines[ from_row ].index( regexp, index_col )
            if index <= ( @last_finding ? @last_finding.start_col : from_col )
              establish_finding( regexps, search_area, from_row, index, Regexp.last_match )
            end
          end

        elsif direction == :up

          # Check the current row first.

          col_to_check = ( @last_finding ? @last_finding.end_col : from_col ) - 1
          if ( col_to_check >= 0 ) and ( index = @lines[ from_row ][ 0...col_to_check ].rindex( regexp ) )
            match = Regexp.last_match
            found_text = match[ 0 ]
            finding = Finding.new( from_row, index, from_row, index + found_text.length )
            if finding.match( regexps, @lines )
              throw :found
            else
              finding = nil
            end
          end

          # Check above the cursor.

          (from_row - 1).downto( 0 ) do |i|
            if index = @lines[ i ].rindex( regexp )
              match = Regexp.last_match
              found_text = match[ 0 ]
              finding = Finding.new( i, index, i, index + found_text.length )
              if finding.match( regexps, @lines )
                throw :found
              else
                finding = nil
              end
            end
          end

          # Wrap around.

          wrapped = true

          (@lines.length - 1).downto(from_row + 1) do |i|
            if index = @lines[ i ].rindex( regexp )
              match = Regexp.last_match
              found_text = match[ 0 ]
              finding = Finding.new( i, index, i, index + found_text.length )
              if finding.match( regexps, @lines )
                throw :found
              else
                finding = nil
              end
            end
          end

          # And finally, the other side of the current row.

          search_col = ( @last_finding ? @last_finding.start_col : from_col ) + 1
          if index = @lines[ from_row ].rindex( regexp )
            if index > search_col
              match = Regexp.last_match
              found_text = match[ 0 ]
              finding = Finding.new( from_row, index, from_row, index + found_text.length )
              if finding.match( regexps, @lines )
                throw :found
              else
                finding = nil
              end
            end
          end
        end
      end

      if ! finding
        remove_selection DONT_DISPLAY
        clear_matches DO_DISPLAY
        if ! options[ :quiet ]
          @diakonos.set_iline "/#{regexp.source}/ not found."
        end
      else
        if wrapped && ! options[ :quiet ]
          if @search_area
            @diakonos.set_iline( "(search wrapped around to start of search area)" )
          else
            @diakonos.set_iline( "(search wrapped around BOF/EOF)" )
          end
        end

        remove_selection( DONT_DISPLAY )
        @last_finding = finding
        if @settings[ "found_cursor_start" ]
          anchor_selection( finding.end_row, finding.end_col, DONT_DISPLAY )
          cursor_to( finding.start_row, finding.start_col )
        else
          anchor_selection( finding.start_row, finding.start_col, DONT_DISPLAY )
          cursor_to( finding.end_row, finding.end_col )
        end
        if show_context_after
          watermark = Curses::lines / 6
          if @last_row - @top_line > watermark
            pitch_view( @last_row - @top_line - watermark )
          end
        end

        @changing_selection = false

        if regexps.length == 1
          @highlight_regexp = regexp
          highlight_matches
        else
          clear_matches
        end
        display

        if replacement
          # Substitute placeholders (e.g. \1) in str for the group matches of the last match.
          actual_replacement = replacement.dup
          actual_replacement.gsub!( /\\(\\|\d+)/ ) { |m|
            ref = $1
            if ref == "\\"
              "\\"
            else
              match[ ref.to_i ]
            end
          }

          choice = auto_choice || @diakonos.get_choice(
            "Replace?",
            [ CHOICE_YES, CHOICE_NO, CHOICE_ALL, CHOICE_CANCEL, CHOICE_YES_AND_STOP ],
            CHOICE_YES
          )
          case choice
          when CHOICE_YES
            paste [ actual_replacement ]
            find( regexps, :direction => direction, :replacement => replacement )
          when CHOICE_ALL
            replace_all( regexp, replacement )
          when CHOICE_NO
            find( regexps, :direction => direction, :replacement => replacement )
          when CHOICE_CANCEL
            # Do nothing further.
          when CHOICE_YES_AND_STOP
            paste [ actual_replacement ]
            # Do nothing further.
          end
        end
      end
    end

    def replace_all( regexp, replacement )
      return  if( regexp.nil? or replacement.nil? )

      @lines = @lines.collect { |line|
        line.gsub( regexp, replacement )
      }
      set_modified
      clear_matches
      display
    end

    def highlight_matches( regexp = @highlight_regexp )
      @highlight_regexp = regexp
      return  if @highlight_regexp.nil?
      found_marks = @lines[ @top_line...(@top_line + @diakonos.main_window_height) ].grep_indices( @highlight_regexp ).collect do |line_index, start_col, end_col|
        TextMark.new( @top_line + line_index, start_col, @top_line + line_index, end_col, @settings[ "lang.#{@language}.format.found" ] )
      end
      @text_marks[ :found ] = found_marks
    end

    def clear_matches( do_display = DONT_DISPLAY )
      @text_marks[ :found ] = []
      @highlight_regexp = nil
      display  if do_display
    end

    def pos_of_next( regexp, start_row, start_col )
      row, col = start_row, start_col
      col = @lines[ row ].index( regexp, col )
      while col.nil? && row < @lines.length - 1
        row += 1
        col = @lines[ row ].index( regexp )
      end
      if col
        [ row, col, Regexp.last_match( 0 ) ]
      end
    end

    def pos_of_prev( regexp, start_row, start_col )
      row, col = start_row, start_col
      if col < 0
        row -= 1
        col = -1
      end
      col = @lines[ row ].rindex( regexp, col )
      while col.nil? && row > 0
        row -= 1
        col = @lines[ row ].rindex( regexp )
      end
      if col
        [ row, col, Regexp.last_match( 0 ) ]
      end
    end

    def pos_of_pair_match( row = @last_row, col = @last_col )
      c = @lines[ row ][ col ]
      data = CHARACTER_PAIRS[ c ]
      return  if data.nil?
      d = data[ :partner ]
      c_ = Regexp.escape c
      d_ = Regexp.escape d
      target = /(?:#{c_}|#{d_})/

      case data[ :direction ]
      when :forward
        row, col, char = pos_of_next( target, row, col + 1 )
        while char == c  # Take care of nested pairs
          row, col = pos_of_pair_match( row, col )
          break  if col.nil?
          row, col, char = pos_of_next( target, row, col + 1 )
        end
      when :backward
        row, col, char = pos_of_prev( target, row, col - 1 )
        while char == c  # Take care of nested pairs
          row, col = pos_of_pair_match( row, col )
          break  if col.nil?
          row, col, char = pos_of_prev( target, row, col - 1 )
        end
      end
      [ row, col ]
    end

    def go_to_pair_match
      row, col = pos_of_pair_match
      if row && col
        if cursor_to( row, col )
          highlight_pair
          display
        end
      end
    end

    def highlight_pair
      match_row, match_col = pos_of_pair_match( @last_row, @last_col )
      if match_col.nil?
        @text_marks[ :pair ] = nil
      else
        @text_marks[ :pair ] = TextMark.new(
          match_row,
          match_col,
          match_row,
          match_col + 1,
          @settings[ "lang.#{@language}.format.pair" ] || @settings[ "lang.shared.format.pair" ]
        )
      end
    end

    def clear_pair_highlight
      @text_marks[ :pair ] = nil
    end

    def find_again( last_search_regexps, direction = @last_search_direction )
      if @last_search_regexps.nil?
        @last_search_regexps = last_search_regexps
      end
      if @last_search_regexps
        find( @last_search_regexps, :direction => direction )
      end
    end

    def seek( regexp, direction = :down )
      return  if regexp.nil? || regexp == //

      found_row = nil
      found_col = nil
      found_text = nil

      catch :found do
        if direction == :down
          # Check the current row first.

          index, match_text = @lines[ @last_row ].group_index( regexp, @last_col + 1 )
          if index
            found_row = @last_row
            found_col = index
            found_text = match_text
            throw :found
          end

          # Check below the cursor.

          ( (@last_row + 1)...@lines.length ).each do |i|
            index, match_text = @lines[ i ].group_index( regexp )
            if index
              found_row = i
              found_col = index
              found_text = match_text
              throw :found
            end
          end

        else
          # Check the current row first.

          #col_to_check = ( @last_found_col or @last_col ) - 1
          col_to_check = @last_col - 1
          if col_to_check >= 0
            index, match_text = @lines[ @last_row ].group_rindex( regexp, col_to_check )
            if index
              found_row = @last_row
              found_col = index
              found_text = match_text
              throw :found
            end
          end

          # Check above the cursor.

          (@last_row - 1).downto( 0 ) do |i|
            index, match_text = @lines[ i ].group_rindex( regexp )
            if index
              found_row = i
              found_col = index
              found_text = match_text
              throw :found
            end
          end
        end
      end

      if found_text
        #@last_found_row = found_row
        #@last_found_col = found_col
        cursor_to( found_row, found_col )

        display
      end
    end

    # Returns an Array of results, where each result is a String usually
    # containing \n's due to context
    def grep( regexp_source )
      ::Diakonos.grep_array(
        Regexp.new( regexp_source ),
        @lines,
        @diakonos.settings[ 'grep.context' ],
        "#{File.basename( @name )}:",
        @key
      )
    end

  end

end