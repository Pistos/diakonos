module Diakonos
  module Functions

    # Move one character left, then delete one character.
    #
    # @see Diakonos::Buffer#delete
    def backspace
      delete  if( @current_buffer.changing_selection or cursor_left( Buffer::STILL_TYPING ) )
    end

    # Insert a carriage return (newline) at the current cursor location.
    # Deletes any currently selected text.
    def carriage_return
      @current_buffer.carriage_return
      @current_buffer.delete_selection
    end

    def delete
      @current_buffer.delete
    end

    def delete_line
      removed_text = @current_buffer.delete_line
      @clipboard.add_clip( [ removed_text, "" ] ) if removed_text
    end

  end
end