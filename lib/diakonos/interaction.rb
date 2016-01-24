module Diakonos
  DONT_COMPLETE = false

  class Diakonos
    attr_reader :readline

    # completion_array is the array of strings that tab completion can use
    # @param options :initial_text, :completion_array, :history, :do_complete, :on_dirs
    def get_user_input( prompt, options = {}, &block )
      if @playing_macro
        return @macro_input_history.shift
      end

      options[ :history ] ||= @rlh_general
      options[ :initial_text ] ||= ""
      options[ :do_complete ] ||= DONT_COMPLETE
      options[ :on_dirs ] ||= :go_into_dirs
      will_display_after_select = options.fetch( :will_display_after_select, false )

      cursor_pos = set_iline( prompt )
      @readline = Readline.new(
        list_manager: self,
        keystroke_processor: self,
        testing: @testing,
        window: @win_interaction,
        start_pos: cursor_pos,
        options: options,
        &block
      )

      retval = @readline.get_input
      if will_display_after_select
        close_list_buffer  do_display: ! retval
      else
        close_list_buffer
      end
      options[ :history ][ -1 ] = @readline.input
      @readline = nil

      if @macro_history
        @macro_input_history.push retval
      end
      set_iline

      retval
    end

    def get_choice(*args)
      @interaction_handler.get_choice *args
    end
  end
end
