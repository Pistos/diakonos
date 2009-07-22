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

    def select_all
      @current_buffer.select_all
    end

    def select_block( beginning = nil, ending = nil, including_ending = true )
      if beginning.nil?
        input = get_user_input( "Start at regexp: " )
        if input
          beginning = Regexp.new input
        end
      end
      if beginning and ending.nil?
        input = get_user_input( "End before regexp: " )
        if input
          ending = Regexp.new input
        end
      end
      if beginning and ending
        @current_buffer.select( beginning, ending, including_ending )
      end
    end

    def selection_mode_block
      @current_buffer.selection_mode_block
      update_status_line
    end

    def selection_mode_normal
      @current_buffer.selection_mode_normal
      update_status_line
    end

    def toggle_selection
      @current_buffer.toggle_selection
      update_status_line
    end

    def select_line
      @current_buffer.select_current_line
      update_status_line
    end

    def select_wrapping_block
      @current_buffer.select_wrapping_block
      update_status_line
    end

  end
end