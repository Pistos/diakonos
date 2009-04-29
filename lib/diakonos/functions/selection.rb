module Diakonos
  module Functions

    # Begins selecting text by anchoring (marking) the start of a selection.
    def anchor_selection
      @current_buffer.anchor_selection
      update_status_line
    end

    # Removes the highlighting from any text that matches the most recent
    # search.
    def clear_matches
      @current_buffer.clear_matches Buffer::DO_DISPLAY
    end

    def remove_selection
      @current_buffer.remove_selection
      update_status_line
    end

  end
end