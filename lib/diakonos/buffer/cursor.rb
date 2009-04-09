module Diakonos

  class Buffer

    # Returns true iff the cursor changed positions in the buffer.
    def cursorTo( row, col, do_display = DONT_DISPLAY, stopped_typing = STOPPED_TYPING, adjust_row = ADJUST_ROW )
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

      new_col = tabExpandedColumn( col, row )
      view_changed = showCharacter( row, new_col )
      @last_screen_y = row - @top_line
      @last_screen_x = new_col - @left_column

      @typing = false if stopped_typing
      @last_row = row
      @last_col = col
      @last_screen_col = new_col
      changed = ( @last_row != old_last_row or @last_col != old_last_col )
      if changed
        recordMarkStartAndEnd

        removed = false
        if not @changing_selection and selecting?
          removeSelection( DONT_DISPLAY )
          removed = true
        end
        if removed or ( do_display and ( selecting? or view_changed ) )
          display
        else
          @diakonos.display_mutex.synchronize do
            @win_main.setpos( @last_screen_y, @last_screen_x )
          end
        end
        @diakonos.updateStatusLine
        @diakonos.updateContextLine

        @diakonos.remember_buffer self
      end

      changed
    end

    def cursorReturn( direction )
      delta = 0
      if @cursor_stack_pointer.nil?
        pushCursorState( @top_line, @last_row, @last_col, DONT_CLEAR_STACK_POINTER )
        delta = 1
      end
      case direction
      when :forward
        @cursor_stack_pointer = ( @cursor_stack_pointer || 0 ) + 1
        #when :backward
      else
        @cursor_stack_pointer = ( @cursor_stack_pointer || @cursor_stack.length ) - 1 - delta
      end

      return_pointer = @cursor_stack_pointer

      if @cursor_stack_pointer < 0
        return_pointer = @cursor_stack_pointer = 0
      elsif @cursor_stack_pointer >= @cursor_stack.length
        return_pointer = @cursor_stack_pointer = @cursor_stack.length - 1
      else
        cursor_state = @cursor_stack[ @cursor_stack_pointer ]
        if cursor_state
          pitchView( cursor_state[ :top_line ] - @top_line, DONT_PITCH_CURSOR, DO_DISPLAY )
          cursorTo( cursor_state[ :row ], cursor_state[ :col ] )
          @diakonos.updateStatusLine
        end
      end

      [ return_pointer, @cursor_stack.size ]
    end

    def cursorToEOF
      cursorTo( @lines.length - 1, @lines[ -1 ].length, DO_DISPLAY )
    end

    def cursorToBOL
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
      cursorTo( row, col, DO_DISPLAY )
    end

    def cursorToEOL
      y = @win_main.cury
      end_col = lineAt( y ).length
      last_char_col = lineAt( y ).rstrip.length
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
      cursorTo( @last_row, col, DO_DISPLAY )
    end

    # Top of view
    def cursorToTOV
      cursorTo( rowOf( 0 ), @last_col, DO_DISPLAY )
    end
    # Bottom of view
    def cursorToBOV
      cursorTo( rowOf( 0 + @diakonos.main_window_height - 1 ), @last_col, DO_DISPLAY )
    end

    # col and row are given relative to the buffer, not any window or screen.
    # Returns true if the view changed positions.
    def showCharacter( row, col )
      old_top_line = @top_line
      old_left_column = @left_column

      while row < @top_line + @settings[ "view.margin.y" ]
        amount = (-1) * @settings[ "view.jump.y" ]
        break if( pitchView( amount, DONT_PITCH_CURSOR, DONT_DISPLAY ) != amount )
      end
      while row > @top_line + @diakonos.main_window_height - 1 - @settings[ "view.margin.y" ]
        amount = @settings[ "view.jump.y" ]
        break if( pitchView( amount, DONT_PITCH_CURSOR, DONT_DISPLAY ) != amount )
      end

      while col < @left_column + @settings[ "view.margin.x" ]
        amount = (-1) * @settings[ "view.jump.x" ]
        break if( panView( amount, DONT_DISPLAY ) != amount )
      end
      while col > @left_column + @diakonos.main_window_width - @settings[ "view.margin.x" ] - 2
        amount = @settings[ "view.jump.x" ]
        break if( panView( amount, DONT_DISPLAY ) != amount )
      end

      @top_line != old_top_line or @left_column != old_left_column
    end

  end

end