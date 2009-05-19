module Diakonos
  module Functions

    # Returns true iff the cursor changed positions
    def cursor_down
      @current_buffer.cursor_to(
        @current_buffer.last_row + 1,
        @current_buffer.last_col,
        @do_display,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # Returns true iff the cursor changed positions
    def cursor_left( stopped_typing = Buffer::STOPPED_TYPING )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col - 1,
        @do_display,
        stopped_typing
      )
    end

    def cursor_right( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col + amount,
        @do_display,
        stopped_typing
      )
    end

    # Returns true iff the cursor changed positions
    def cursor_up
      @current_buffer.cursor_to(
        @current_buffer.last_row - 1,
        @current_buffer.last_col,
        @do_display,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    def cursor_bof
      @current_buffer.cursor_to( 0, 0, @do_display )
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

    def page_up
      if @current_buffer.pitch_view( -main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        cursor_bof
      end
      update_status_line
      update_context_line
    end

    def page_down
      if @current_buffer.pitch_view( main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        @current_buffer.cursor_to_eof
      end
      update_status_line
      update_context_line
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