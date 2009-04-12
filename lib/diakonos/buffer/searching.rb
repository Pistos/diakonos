module Diakonos

  class Buffer

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

      finding = nil
      wrapped = false
      match = nil

      catch :found do

        if direction == :down
          # Check the current row first.

          if index = @lines[ from_row ].index( regexp, ( @last_finding ? @last_finding.start_col : from_col ) + 1 )
            match = Regexp.last_match
            found_text = match[ 0 ]
            finding = Finding.new( from_row, index, from_row, index + found_text.length )
            if finding.match( regexps, @lines )
              throw :found
            else
              finding = nil
            end
          end

          # Check below the cursor.

          ( (from_row + 1)...@lines.length ).each do |i|
            if index = @lines[ i ].index( regexp )
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

          ( 0...from_row ).each do |i|
            if index = @lines[ i ].index( regexp )
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

          #if index = @lines[ from_row ].index( regexp, ( @last_finding ? @last_finding.start_col : from_col ) - 1 )
          if index = @lines[ from_row ].index( regexp )
            if index <= ( @last_finding ? @last_finding.start_col : from_col )
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

      if finding
        if wrapped and not options[ :quiet ]
          @diakonos.setILine( "(search wrapped around BOF/EOF)" )
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
            pitchView( @last_row - @top_line - watermark )
          end
        end

        @changing_selection = false

        if regexps.length == 1
          @highlight_regexp = regexp
          highlightMatches
        else
          clearMatches
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
            replaceAll( regexp, replacement )
          when CHOICE_NO
            find( regexps, :direction => direction, :replacement => replacement )
          when CHOICE_CANCEL
            # Do nothing further.
          when CHOICE_YES_AND_STOP
            paste [ actual_replacement ]
            # Do nothing further.
          end
        end
      else
        remove_selection DONT_DISPLAY
        clearMatches DO_DISPLAY
        if not options[ :quiet ]
          @diakonos.setILine "/#{regexp.source}/ not found."
        end
      end
    end

    def replaceAll( regexp, replacement )
      return  if( regexp.nil? or replacement.nil? )

      @lines = @lines.collect { |line|
        line.gsub( regexp, replacement )
      }
      set_modified
      clearMatches
      display
    end

    def highlightMatches( regexp = @highlight_regexp )
      @highlight_regexp = regexp
      return  if @highlight_regexp.nil?
      found_marks = @lines[ @top_line...(@top_line + @diakonos.main_window_height) ].grep_indices( @highlight_regexp ).collect do |line_index, start_col, end_col|
        TextMark.new( @top_line + line_index, start_col, @top_line + line_index, end_col, @settings[ "lang.#{@language}.format.found" ] )
      end
      @text_marks = [ @text_marks[ 0 ] ] + found_marks
    end

    def clearMatches( do_display = DONT_DISPLAY )
      selection = @text_marks[ SELECTION ]
      @text_marks = Array.new
      @text_marks[ SELECTION ] = selection
      @highlight_regexp = nil
      display  if do_display
    end

    def findAgain( last_search_regexps, direction = @last_search_direction )
      if @last_search_regexps.nil?
        @last_search_regexps = last_search_regexps
      end
      if @last_search_regexps
        find( @last_search_regexps, :direction => direction )
      end
    end

    def seek( regexp, direction = :down )
      return if regexp.nil? or regexp == //

      found_row = nil
      found_col = nil
      found_text = nil
      wrapped = false

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