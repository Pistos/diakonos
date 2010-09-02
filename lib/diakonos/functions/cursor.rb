module Diakonos

  CLEAR_STACK_POINTER = true
  DONT_CLEAR_STACK_POINTER = false
  DIFFERENT_FILE = true
  NOT_DIFFERENT_FILE = false

  module Functions

    # @return [true,false] true iff the cursor changed positions
    def cursor_down
      buffer_current.cursor_to(
        buffer_current.last_row + 1,
        buffer_current.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # @return [true,false] true iff the cursor changed positions
    def cursor_left( stopped_typing = Buffer::STOPPED_TYPING )
      buffer_current.cursor_to(
        buffer_current.last_row,
        buffer_current.last_col - 1,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    # Pops the cursor stack.
    # @param [Symbol] direction
    #   Either :backward (default) or :forward.
    # @param [Boolean] different_file
    #   Whether to pop just one frame (default), or many frames until a different file is reached.
    # @see Diakonos::DIFFERENT_FILE
    # @see Diakonos::NOT_DIFFERENT_FILE
    def cursor_return( direction = :backward, different_file = NOT_DIFFERENT_FILE )
      delta = 0
      if @cursor_stack_pointer.nil?
        push_cursor_state(
          buffer_current.top_line,
          buffer_current.last_row,
          buffer_current.last_col,
          DONT_CLEAR_STACK_POINTER
        )
        delta = 1
      end

      orig_ptr = @cursor_stack_pointer
      case direction
      when :backward, 'backward'
        @cursor_stack_pointer = ( @cursor_stack_pointer || @cursor_stack.length ) - 1 - delta
        while different_file && @cursor_stack[ @cursor_stack_pointer ] && @cursor_stack[ @cursor_stack_pointer ][ :buffer ] == buffer_current
          @cursor_stack_pointer -= 1
        end
      when :forward, 'forward'
        @cursor_stack_pointer = ( @cursor_stack_pointer || 0 ) + 1
        while different_file && @cursor_stack[ @cursor_stack_pointer ] && @cursor_stack[ @cursor_stack_pointer ][ :buffer ] == buffer_current
          @cursor_stack_pointer += 1
        end
      end
      if @cursor_stack[ @cursor_stack_pointer ].nil? && orig_ptr
        @cursor_stack_pointer = orig_ptr
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

    # @return [true,false] true iff the cursor changed positions
    def cursor_right( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
      buffer_current.cursor_to(
        buffer_current.last_row,
        buffer_current.last_col + amount,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    # @return [true,false] true iff the cursor changed positions
    def cursor_up
      buffer_current.cursor_to(
        buffer_current.last_row - 1,
        buffer_current.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # Moves the cursor to the beginning of the current buffer.
    # @return [true,false] true iff the cursor changed positions
    def cursor_bof
      buffer_current.cursor_to( 0, 0, Buffer::DO_DISPLAY )
    end

    # Moves the cursor to the beginning of the current line.
    def cursor_bol
      buffer_current.cursor_to_bol
    end

    # Moves the cursor to the end of the current line.
    def cursor_eol
      buffer_current.cursor_to_eol
    end

    # Moves the cursor to the end of the current buffer.
    def cursor_eof
      buffer_current.cursor_to_eof
    end

    # Moves the cursor to the top of the viewport of the current buffer.
    def cursor_tov
      buffer_current.cursor_to_tov
    end

    # Moves the cursor to the bottom of the viewport of the current buffer.
    def cursor_bov
      buffer_current.cursor_to_bov
    end

    # Moves the cursor to the beginning of the parent code block.
    def go_block_outer
      buffer_current.go_block_outer
    end
    # Moves the cursor to the beginning of the first child code block.
    def go_block_inner
      buffer_current.go_block_inner
    end
    # Moves the cursor to the beginning of the next code block at the same
    # indentation level as the current one.
    def go_block_next
      buffer_current.go_block_next
    end
    # Moves the cursor to the beginning of the previous code block at the same
    # indentation level as the current one.
    def go_block_previous
      buffer_current.go_block_previous
    end

    # Moves the cursor to the next occurrence of the given character.
    # @param [String] char  The character to go to
    def go_to_char( char = nil )
      char ||= get_char( "Type character to go to..." )

      if char
        moved = buffer_current.go_to_char( char )
        if ! moved
          set_iline "'#{char}' not found."
        end
      end
    end

    # Moves the cursor to the closest previous occurrence of the given character.
    # @param [String] char  The character to go to
    def go_to_char_previous( char = nil )
      char ||= get_char( "Type character to go to..." )

      if char
        moved = buffer_current.go_to_char_previous( char )
        if ! moved
          set_iline "'#{char}' not found."
        end
      end
    end

    # Prompts the user for a line number or line delta, with optional column
    # number.  Moves the cursor there.
    def go_to_line_ask
      input = get_user_input( "Go to [line number|+lines][,column number]: " )
      if input
        row = nil

        if input =~ /([+-]\d+)/
          row = buffer_current.last_row + $1.to_i
          col = buffer_current.last_col
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
          buffer_current.go_to_line( row, col )
        end
      end
    end

    # Pitches the current buffer's view one screenful down.
    def page_down
      if buffer_current.pitch_view( main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        buffer_current.cursor_to_eof
      end
      update_status_line
      update_context_line
    end

    # Pitches the current buffer's view one screenful up.
    def page_up
      if buffer_current.pitch_view( -main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        cursor_bof
      end
      update_status_line
      update_context_line
    end

    # Scrolls the current buffer's view down, as determined by the
    # view.scroll_amount setting.
    def scroll_down
      buffer_current.pitch_view( @settings[ "view.scroll_amount" ] || 1 )
      update_status_line
      update_context_line
    end

    # Scrolls the current buffer's view up, as determined by the
    # view.scroll_amount setting.
    def scroll_up
      if @settings[ "view.scroll_amount" ]
        buffer_current.pitch_view( -@settings[ "view.scroll_amount" ] )
      else
        buffer_current.pitch_view( -1 )
      end
      update_status_line
      update_context_line
    end

  end
end