module Diakonos
  module Functions

    # Returns true iff the cursor changed positions
    def cursor_down
      @current_buffer.cursor_to(
        @current_buffer.last_row + 1,
        @current_buffer.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # Returns true iff the cursor changed positions
    def cursor_left( stopped_typing = Buffer::STOPPED_TYPING )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col - 1,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    def cursor_right( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col + amount,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    # Returns true iff the cursor changed positions
    def cursor_up
      @current_buffer.cursor_to(
        @current_buffer.last_row - 1,
        @current_buffer.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    def cursor_bof
      @current_buffer.cursor_to( 0, 0, Buffer::DO_DISPLAY )
    end

    def cursor_bol
      @current_buffer.cursor_to_bol
    end

    def cursor_eol
      @current_buffer.cursor_to_eol
    end

    def cursor_eof
      @current_buffer.cursor_to_eof
    end

    # Top of view
    def cursor_tov
      @current_buffer.cursor_to_tov
    end

    # Bottom of view
    def cursor_bov
      @current_buffer.cursor_to_bov
    end

    def cursor_return( dir_str = "backward" )
      stack_pointer, stack_size = @current_buffer.cursor_return( direction_of( dir_str, :backward ) )
      set_iline( "Location: #{stack_pointer+1}/#{stack_size}" )
    end

  end
end