module Diakonos

  TAB       = 9
  ENTER     = 13
  ESCAPE    = 27
  BACKSPACE = 127
  CTRL_C    = 3
  CTRL_D    = 4
  CTRL_K    = 11
  CTRL_Q    = 17
  CTRL_H    = 263
  CTRL_W    = 23
  RESIZE2   = 4294967295

  DO_COMPLETE   = true
  DONT_COMPLETE = false

  CHOICE_NO           = 0
  CHOICE_YES          = 1
  CHOICE_ALL          = 2
  CHOICE_CANCEL       = 3
  CHOICE_YES_TO_ALL   = 4
  CHOICE_NO_TO_ALL    = 5
  CHOICE_YES_AND_STOP = 6
  CHOICE_DELETE       = 7
  CHOICE_KEYS = [
    [ "n".ord, "N".ord ],
    [ "y".ord, "Y".ord ],
    [ "a".ord, "A".ord ],
    [ "c".ord, "C".ord, ESCAPE, CTRL_C, CTRL_D, CTRL_Q ],
    [ "e".ord ],
    [ "o".ord ],
    [ "s".ord ],
    [ "d".ord ],
  ]
  CHOICE_STRINGS = [ '(n)o', '(y)es', '(a)ll', '(c)ancel', 'y(e)s to all', 'n(o) to all', 'yes and (s)top', '(d)elete' ]

  class Diakonos
    attr_reader :readline

    # completion_array is the array of strings that tab completion can use
    # @param options :initial_text, :completion_array, :history, :do_complete, :on_dirs
    def get_user_input( prompt, options = {}, &block )
      options[ :history ] ||= @rlh_general
      options[ :initial_text ] ||= ""
      options[ :do_complete ] ||= DONT_COMPLETE
      options[ :on_dirs ] ||= :go_into_dirs
      will_display_after_select = options.fetch( :will_display_after_select, false )

      if @playing_macro
        retval = @macro_input_history.shift
      else
        cursor_pos = set_iline( prompt )
        @readline = Readline.new( self, @win_interaction, cursor_pos, options, &block )

        while ! @readline.done?
          process_keystroke Array.new, 'input'
        end
        retval = @readline.input
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
      end
      retval
    end

    def interaction_blink( message = nil )
      terminate_message
      set_iline @settings[ 'interaction.blink_string' ]
      sleep @settings[ 'interaction.blink_duration' ]
      set_iline message if message
    end

    # choices should be an array of CHOICE_* constants.
    # default is what is returned when Enter is pressed.
    def get_choice( prompt, choices, default = nil )
      retval = @iterated_choice
      if retval
        @choice_iterations -= 1
        if @choice_iterations < 1
          @iterated_choice = nil
          @do_display = true
        end
        return retval
      end

      @saved_main_x = @win_main.curx
      @saved_main_y = @win_main.cury

      msg = prompt + " "
      choice_strings = choices.collect do |choice|
        CHOICE_STRINGS[ choice ]
      end
      msg << choice_strings.join( ", " )

      if default
        set_iline msg
      else
        show_message msg
      end

      c = nil
      while retval.nil?
        ch = @win_interaction.getch
        c = ch.ord  if ch

        case c
        when Curses::KEY_NPAGE
          page_down
        when Curses::KEY_PPAGE
          page_up
        else
          if @message_expiry and Time.now < @message_expiry
            interaction_blink
            show_message msg
          else
            case c
            when ENTER
              retval = default
            when '0'.ord..'9'.ord
              if @choice_iterations < 1
                @choice_iterations = ( c - '0'.ord )
              else
                @choice_iterations = @choice_iterations * 10 + ( c - '0'.ord )
              end
            else
              choices.each do |choice|
                if CHOICE_KEYS[ choice ].include? c
                  retval = choice
                  break
                end
              end
            end

            if retval.nil?
              interaction_blink( msg )
            end
          end
        end
      end

      terminate_message
      set_iline

      if @choice_iterations > 0
        @choice_iterations -= 1
        @iterated_choice = retval
        @do_display = false
      end

      retval
    end

    def get_char( prompt )
      set_iline prompt
      char = @win_main.getch
      set_iline
      char
    end

  end
end
