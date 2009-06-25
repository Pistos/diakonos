module Diakonos
  module Functions

    def readline_abort
      @readline.abort
    end

    def readline_accept
      @readline.accept
    end

    def readline_backspace
      @readline.backspace
    end

    def readline_complete_input
      @readline.complete_input
    end

    def readline_cursor_left
      @readline.cursor_left
    end

    def readline_cursor_right
      @readline.cursor_right
    end

    def readline_cursor_bol
      @readline.cursor_bol
    end

    def readline_cursor_eol
      @readline.cursor_eol
    end

    def readline_cursor_up
      if showing_list?
        if list_item_selected?
          previous_list_item
        end
        @readline.set_input select_list_item
      else
        @readline.history_up
      end
      @readline.cursor_write_input
    end

    def readline_cursor_down
      if showing_list?
        if list_item_selected?
          next_list_item
        end
        @readline.set_input select_list_item
      else
        @readline.history_down
      end
      @readline.cursor_write_input
    end

    def readline_delete
      @readline.delete
    end

    def readline_delete_line
      @readline.delete_line
    end

    def readline_delete_word
      @readline.delete_word
    end

    def readline_grep_context_decrease
      decrease_grep_context
      @readline.call_block
    end

    def readline_grep_context_increase
      increase_grep_context
      @readline.call_block
    end

    def readline_page_down
      page_down
      @readline.list_sync
    end

    def readline_page_up
      page_up
      @readline.list_sync
    end

  end
end