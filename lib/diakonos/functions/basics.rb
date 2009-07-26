module Diakonos
  module Functions

    # Move one character left, then delete one character.
    #
    # @see Diakonos::Buffer#delete
    def backspace
      if( @current_buffer.changing_selection || cursor_left( Buffer::STILL_TYPING ) )
        delete
      end
    end

    # Insert a carriage return (newline) at the current cursor location.
    # Deletes any currently selected text.
    def carriage_return
      @current_buffer.carriage_return
      @current_buffer.delete_selection
    end

    # Calls Buffer#delete on the current_buffer.
    def delete
      @current_buffer.delete
    end

    # Deletes the current line and adds it to the clipboard.
    def delete_line
      removed_text = @current_buffer.delete_line
      if removed_text
        @clipboard.add_clip( [ removed_text, "" ] )
      end
    end

  end
end