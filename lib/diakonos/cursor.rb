module Diakonos
  class Diakonos
    def cursor_stack_remove_buffer( buffer )
      @cursor_stack.delete_if { |frame|
        frame[ :buffer ] == buffer
      }
    end
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

end