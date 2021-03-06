module Diakonos
  module Functions

    # Begins selecting text by anchoring (marking) the start of a selection.
    def anchor_selection
      buffer_current.anchor_selection
      update_status_line
    end

    # Used for "shift+arrow" style selection.
    def anchor_unanchored_selection( *method_and_args )
      buffer_current.anchor_unanchored_selection
      if method_and_args[0]
        self.send method_and_args[0], *method_and_args[1..-1]
      end
      update_status_line
    end

    # Removes the highlighting from any text that matches the most recent
    # search.
    def clear_matches
      buffer_current.clear_matches Buffer::DO_DISPLAY
    end

    # Unselects any current selection (stops selecting).
    def remove_selection
      buffer_current.remove_selection
      update_status_line
    end

    # Selects the entire buffer contents.
    def select_all
      buffer_current.select_all
    end

    # Selects text between two regexps.
    def select_block( beginning = nil, ending = nil, including_ending = true )
      if beginning.nil?
        input = get_user_input( "Start at regexp: " )
        if input
          beginning = Regexp.new input
        end
      end
      if beginning && ending.nil?
        input = get_user_input( "End before regexp: " )
        if input
          ending = Regexp.new input
        end
      end
      if beginning && ending
        buffer_current.select( beginning, ending, including_ending )
      end
    end

    # Changes selection mode to block mode (rectangular selection).
    def selection_mode_block
      buffer_current.selection_mode_block
      update_status_line
    end

    # Changes selection mode to normal mode (flow selection).
    def selection_mode_normal
      buffer_current.selection_mode_normal
      update_status_line
    end

    # If currently selecting, stops selecting.
    # If not currently selecting, begins selecting.
    def toggle_selection
      buffer_current.toggle_selection
      update_status_line
    end

    # Selects the current line.
    def select_line
      buffer_current.select_current_line
      update_status_line
    end

    # Selects the code block which wraps the current cursor position.
    # Execute multiple times in succession to select increasingly outer code blocks.
    def select_wrapping_block
      buffer_current.select_wrapping_block
      update_status_line
    end

    # Selects the word at the current cursor position.
    # If the cursor is not on a word character, the first word following the cursor is selected.
    def select_word
      buffer_current.select_word
    end

    def select_word_another
      buffer_current.select_word_another
    end

  end
end
