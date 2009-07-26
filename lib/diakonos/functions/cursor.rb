module Diakonos

  CLEAR_STACK_POINTER = true
  DONT_CLEAR_STACK_POINTER = false

  module Functions

    # @return [true,false] true iff the cursor changed positions
    def cursor_down
      @current_buffer.cursor_to(
        @current_buffer.last_row + 1,
        @current_buffer.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # @return [true,false] true iff the cursor changed positions
    def cursor_left( stopped_typing = Buffer::STOPPED_TYPING )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col - 1,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    # Pops the cursor stack.
    def cursor_return( direction = :backward )
      delta = 0
      if @cursor_stack_pointer.nil?
        push_cursor_state(
          @current_buffer.top_line,
          @current_buffer.last_row,
          @current_buffer.last_col,
          DONT_CLEAR_STACK_POINTER
        )
        delta = 1
      end

      case direction
      when :backward, 'backward'
        @cursor_stack_pointer = ( @cursor_stack_pointer || @cursor_stack.length ) - 1 - delta
      when :forward, 'forward'
        @cursor_stack_pointer = ( @cursor_stack_pointer || 0 ) + 1
      end

      return_pointer = @cursor_stack_pointer

      if @cursor_stack_pointer < 0
        return_pointer = @cursor_stack_pointer = 0
      elsif @cursor_stack_pointer >= @cursor_stack.length
        return_pointer = @cursor_stack_pointer = @cursor_stack.length - 1
      else
        cursor_state = @cursor_stack[ @cursor_stack_pointer ]
        if cursor_state
          buffer = cursor_state[ :buffer ]
          switch_to buffer
          buffer.pitch_view( cursor_state[ :top_line ] - buffer.top_line, Buffer::DONT_PITCH_CURSOR, Buffer::DO_DISPLAY )
          buffer.cursor_to( cursor_state[ :row ], cursor_state[ :col ] )
          update_status_line
        end
      end

      set_iline "Location: #{return_pointer+1}/#{@cursor_stack.size}"
    end

    def cursor_right( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col + amount,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    # @return [true,false] true iff the cursor changed positions
    def cursor_up
      @current_buffer.cursor_to(
        @current_buffer.last_row - 1,
        @current_buffer.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # Moves the cursor to the beginning of the current buffer.
    def cursor_bof
      @current_buffer.cursor_to( 0, 0, Buffer::DO_DISPLAY )
    end

    # Moves the cursor to the beginning of the current line.
    def cursor_bol
      @current_buffer.cursor_to_bol
    end

    # Moves the cursor to the end of the current line.
    def cursor_eol
      @current_buffer.cursor_to_eol
    end

    # Moves the cursor to the end of the current buffer.
    def cursor_eof
      @current_buffer.cursor_to_eof
    end

    # Moves the cursor to the top of the viewport of the current buffer.
    def cursor_tov
      @current_buffer.cursor_to_tov
    end

    # Moves the cursor to the bottom of the viewport of the current buffer.
    def cursor_bov
      @current_buffer.cursor_to_bov
    end

    def go_block_outer
      @current_buffer.go_block_outer
    end
    def go_block_inner
      @current_buffer.go_block_inner
    end
    def go_block_next
      @current_buffer.go_block_next
    end
    def go_block_previous
      @current_buffer.go_block_previous
    end

    # Moves the cursor to the next occurrence of the given character.
    def go_to_char( char = nil )
      char ||= get_char( "Type character to go to..." )

      if char
        moved = @current_buffer.go_to_char( char )
        if ! moved
          set_iline "'#{char}' not found."
        end
      end
    end

    # Moves the cursor to the closest previous occurrence of the given character.
    def go_to_char_previous( char = nil )
      char ||= get_char( "Type character to go to..." )

      if char
        moved = @current_buffer.go_to_char_previous( char )
        if ! moved
          set_iline "'#{char}' not found."
        end
      end
    end

    def go_to_line_ask
      input = get_user_input( "Go to [line number|+lines][,column number]: " )
      if input
        row = nil

        if input =~ /([+-]\d+)/
          row = @current_buffer.last_row + $1.to_i
          col = @current_buffer.last_col
        else
          input = input.split( /\D+/ ).collect { |n| n.to_i }
          if input.size > 0
            if input[ 0 ] == 0
              row = nil
            else
              row = input[ 0 ] - 1
            end
            if input[ 1 ]
              col = input[ 1 ] - 1
            end
          end
        end

        if row
          @current_buffer.go_to_line( row, col )
        end
      end
    end

    # Pitches the current buffer's view one screenful down.
    def page_down
      if @current_buffer.pitch_view( main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        @current_buffer.cursor_to_eof
      end
      update_status_line
      update_context_line
    end

    def push_cursor_state( top_line, row, col, clear_stack_pointer = CLEAR_STACK_POINTER )
      new_state = {
        buffer: @current_buffer,
        top_line: top_line,
        row: row,
        col: col
      }
      if ! @cursor_stack.include? new_state
        @cursor_stack << new_state
        if clear_stack_pointer
          @cursor_stack_pointer = nil
        end
        clear_non_movement_flag
      end
    end

    def scroll_down
      @current_buffer.pitch_view( @settings[ "view.scroll_amount" ] || 1 )
      update_status_line
      update_context_line
    end

    def scroll_up
      if @settings[ "view.scroll_amount" ]
        @current_buffer.pitch_view( -@settings[ "view.scroll_amount" ] )
      else
        @current_buffer.pitch_view( -1 )
      end
      update_status_line
      update_context_line
    end

  end
end