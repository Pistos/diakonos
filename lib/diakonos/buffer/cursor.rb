module Diakonos

  class Buffer

    attr_reader :last_col, :last_row, :last_screen_x, :last_screen_y, :last_screen_col

    # Returns true iff the cursor changed positions in the buffer.
    def cursor_to( row, col, do_display = DONT_DISPLAY, stopped_typing = STOPPED_TYPING, adjust_row = ADJUST_ROW )
      old_last_row = @last_row
      old_last_col = @last_col

      row = row.fit( 0, @lines.length - 1 )

      if col < 0
        if adjust_row
          if row > 0
            row = row - 1
            col = @lines[ row ].length
          else
            col = 0
          end
        else
          col = 0
        end
      elsif col > @lines[ row ].length
        if adjust_row
          if row < @lines.length - 1
            row = row + 1
            col = 0
          else
            col = @lines[ row ].length
          end
        else
          col = @lines[ row ].length
        end
      end

      if adjust_row
        @desired_column = col
      else
        goto_col = [ @desired_column, @lines[ row ].length ].min
        if col < goto_col
          col = goto_col
        end
      end

      new_col = tab_expanded_column( col, row )
      view_changed = show_character( row, new_col )
      @last_screen_y = row - @top_line
      @last_screen_x = new_col - @left_column

      @typing = false  if stopped_typing
      @last_row = row
      @last_col = col
      @last_screen_col = new_col
      changed = ( @last_row != old_last_row || @last_col != old_last_col )
      if changed
        record_mark_start_and_end

        removed = false
        if not @changing_selection and selecting?
          remove_selection( DONT_DISPLAY )
          removed = true
        end

        old_pair = @text_marks[ :pair ]
        if @settings[ 'view.pairs.highlight' ]
          highlight_pair
        elsif old_pair
          clear_pair_highlight
        end
        highlight_changed = old_pair != @text_marks[ :pair ]

        if removed || ( do_display && ( selecting? || view_changed || highlight_changed ) )
          display
        else
          @diakonos.display_mutex.synchronize do
            @win_main.setpos( @last_screen_y, @last_screen_x )
          end
        end
        @diakonos.update_status_line
        @diakonos.update_context_line
      end

      changed
    end

    def cursor_to_eof
      cursor_to( @lines.length - 1, @lines[ -1 ].length, DO_DISPLAY )
    end

    def cursor_to_bol
      row = @last_row
      case @settings[ "bol_behaviour" ]
      when BOL_ZERO
        col = 0
      when BOL_FIRST_CHAR
        col = ( ( @lines[ row ] =~ /\S/ ) or 0 )
      when BOL_ALT_ZERO
        if @last_col == 0
          col = ( @lines[ row ] =~ /\S/ )
        else
          col = 0
        end
        #when BOL_ALT_FIRST_CHAR
      else
        first_char_col = ( ( @lines[ row ] =~ /\S/ ) or 0 )
        if @last_col == first_char_col
          col = 0
        else
          col = first_char_col
        end
      end
      cursor_to( row, col, DO_DISPLAY )
    end

    def cursor_to_eol
      y = @win_main.cury
      end_col = line_at( y ).length
      last_char_col = line_at( y ).rstrip.length
      case @settings[ 'eol_behaviour' ]
      when EOL_END
        col = end_col
      when EOL_LAST_CHAR
        col = last_char_col
      when EOL_ALT_LAST_CHAR
        if @last_col == last_char_col
          col = end_col
        else
          col = last_char_col
        end
      else
        if @last_col == end_col
          col = last_char_col
        else
          col = end_col
        end
      end
      cursor_to( @last_row, col, DO_DISPLAY )
    end

    # Top of view
    def cursor_to_tov
      cursor_to( row_of( 0 ), @last_col, DO_DISPLAY )
    end
    # Bottom of view
    def cursor_to_bov
      cursor_to( row_of( 0 + @diakonos.main_window_height - 1 ), @last_col, DO_DISPLAY )
    end

    # col and row are given relative to the buffer, not any window or screen.
    # Returns true if the view changed positions.
    def show_character( row, col )
      old_top_line = @top_line
      old_left_column = @left_column

      while row < @top_line + @settings[ "view.margin.y" ]
        amount = (-1) * @settings[ "view.jump.y" ]
        break if( pitch_view( amount, DONT_PITCH_CURSOR, DONT_DISPLAY ) != amount )
      end
      while row > @top_line + @diakonos.main_window_height - 1 - @settings[ "view.margin.y" ]
        amount = @settings[ "view.jump.y" ]
        break if( pitch_view( amount, DONT_PITCH_CURSOR, DONT_DISPLAY ) != amount )
      end

      while col < @left_column + @settings[ "view.margin.x" ]
        amount = (-1) * @settings[ "view.jump.x" ]
        break if( pan_view( amount, DONT_DISPLAY ) != amount )
      end
      while col > @left_column + @diakonos.main_window_width - @settings[ "view.margin.x" ] - 2
        amount = @settings[ "view.jump.x" ]
        break if( pan_view( amount, DONT_DISPLAY ) != amount )
      end

      @top_line != old_top_line or @left_column != old_left_column
    end

    def go_to_line( line = nil, column = nil, do_display = DO_DISPLAY )
      cursor_to( line || @last_row, column || 0, do_display )
    end

    def go_block_outer
      initial_level = indentation_level( @last_row )
      new_row = @last_row
      passed = false
      new_level = initial_level
      ( 0...@last_row ).reverse_each do |row|
        next  if @lines[ row ].strip.empty?
        level = indentation_level( row )
        if ! passed
          passed = ( level < initial_level )
          new_level = level
        else
          if level < new_level
            new_row = ( row+1..@last_row ).find { |r|
              ! @lines[ r ].strip.empty?
            }
            break
          end
        end
      end
      go_to_line( new_row, @lines[ new_row ].index( /\S/ ) )
    end

    def go_block_inner
      initial_level = indentation_level( @last_row )
      new_row = @lines.length
      ( @last_row...@lines.length ).each do |row|
        next  if @lines[ row ].strip.empty?
        level = indentation_level( row )
        if level > initial_level
          new_row = row
          break
        elsif level < initial_level
          new_row = @last_row
          break
        end
      end
      go_to_line( new_row, @lines[ new_row ].index( /\S/ ) )
    end

    def go_block_next
      initial_level = indentation_level( @last_row )
      new_row = @last_row
      passed = false
      ( @last_row+1...@lines.length ).each do |row|
        next  if @lines[ row ].strip.empty?
        level = indentation_level( row )
        if ! passed
          if level < initial_level
            passed = true
          end
        else
          if level == initial_level
            new_row = row
            break
          elsif level < initial_level - 1
            break
          end
        end
      end
      go_to_line( new_row, @lines[ new_row ].index( /\S/ ) )
    end

    def go_block_previous
      initial_level = indentation_level( @last_row )
      new_row = @last_row
      passed = false   # search for unindent
      passed2 = false  # search for reindent
      ( 0...@last_row ).reverse_each do |row|
        next  if @lines[ row ].strip.empty?
        level = indentation_level( row )
        if ! passed
          if level < initial_level
            passed = true
          end
        else
          if ! passed2
            if level >= initial_level
              new_row = row
              passed2 = true
            elsif level <= initial_level - 2
              # No previous block
              break
            end
          else
            if level < initial_level
              new_row = ( row+1..@last_row ).find { |r|
                ! @lines[ r ].strip.empty?
              }
              break
            end
          end
        end
      end
      go_to_line( new_row, @lines[ new_row ].index( /\S/ ) )
    end

    def go_to_char( char )
      r = @last_row
      i = @lines[ r ].index( char, @last_col + 1 )
      if i
        return cursor_to r, i, DO_DISPLAY
      end

      loop do
        r += 1
        break  if r >= @lines.size

        i = @lines[ r ].index( char )
        if i
          return cursor_to r, i, DO_DISPLAY
        end

      end
    end

    def go_to_char_previous( char )
      r = @last_row
      search_from = @last_col - 1
      if search_from >= 0
        i = @lines[ r ].rindex( char, search_from )
        if i
          return cursor_to r, i, DO_DISPLAY
        end
      end

      loop do
        r -= 1
        break  if r < 0

        i = @lines[ r ].rindex( char )
        if i
          return cursor_to r, i, DO_DISPLAY
        end
      end
    end

  end

end