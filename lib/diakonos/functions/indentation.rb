module Diakonos
  module Functions

    def indent
      if ! @current_buffer.changing_selection
        @current_buffer.indent
      else
        @do_display = false
        mark = @current_buffer.selection_mark
        if mark.end_col > 0
          end_row = mark.end_row
        else
          end_row = mark.end_row - 1
        end
        (mark.start_row..end_row).each do |row|
          @current_buffer.indent row, Buffer::DONT_DISPLAY
        end
        @do_display = true
        @current_buffer.display
      end
    end

    def insert_spaces( num_spaces )
      if num_spaces > 0
        @current_buffer.delete_selection
        @current_buffer.insert_string( " " * num_spaces )
        cursor_right( Buffer::STILL_TYPING, num_spaces )
      end
    end

    def insert_tab
      type_character TAB
    end

  end
end