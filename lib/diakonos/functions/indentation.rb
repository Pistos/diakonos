module Diakonos
  module Functions

    def indent
      if ! buffer_current.changing_selection
        buffer_current.indent
      else
        @do_display = false
        mark = buffer_current.selection_mark
        if mark.end_col > 0
          end_row = mark.end_row
        else
          end_row = mark.end_row - 1
        end
        (mark.start_row..end_row).each do |row|
          buffer_current.indent row, Buffer::DONT_DISPLAY
        end
        @do_display = true
        display_buffer buffer_current
      end
    end

    def insert_spaces( num_spaces )
      if num_spaces > 0
        buffer_current.delete_selection
        buffer_current.insert_string( " " * num_spaces )
        cursor_right( Buffer::STILL_TYPING, num_spaces )
      end
    end

    def insert_tab
      type_character TAB
    end

    def parsed_indent
      if( buffer_current.changing_selection )
        @do_display = false
        mark = buffer_current.selection_mark
        (mark.start_row..mark.end_row).each do |row|
          buffer_current.parsed_indent row, Buffer::DONT_DISPLAY
        end
        @do_display = true
        display_buffer buffer_current
      else
        buffer_current.parsed_indent
      end
      update_status_line
      update_context_line
    end

    def unindent
      if( buffer_current.changing_selection )
        @do_display = false
        mark = buffer_current.selection_mark
        if mark.end_col > 0
          end_row = mark.end_row
        else
          end_row = mark.end_row - 1
        end
        (mark.start_row..end_row).each do |row|
          buffer_current.unindent row, Buffer::DONT_DISPLAY
        end
        @do_display = true
        display_buffer buffer_current
      else
        buffer_current.unindent
      end
    end

  end
end