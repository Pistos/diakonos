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
    [ ?n, ?N ],
    [ ?y, ?Y ],
    [ ?a, ?A ],
    [ ?c, ?C, ESCAPE, CTRL_C, CTRL_D, CTRL_Q ],
    [ ?e ],
    [ ?o ],
    [ ?s ],
    [ ?d ],
  ]
  CHOICE_STRINGS = [ '(n)o', '(y)es', '(a)ll', '(c)ancel', 'y(e)s to all', 'n(o) to all', 'yes and (s)top', '(d)elete' ]

  class Diakonos
    # completion_array is the array of strings that tab completion can use
    def getUserInput( prompt, history = @rlh_general, initial_text = "", completion_array = nil, do_complete = DONT_COMPLETE, on_dirs = :go_into_dirs, &block )
      if @playing_macro
        retval = @macro_input_history.shift
      else
        retval = Readline.new( self, @win_interaction, prompt, initial_text, completion_array, history, do_complete, on_dirs, &block ).readline
        if @macro_history
          @macro_input_history.push retval
        end
        setILine
      end
      retval
    end

    def interactionBlink( message = nil )
      terminateMessage
      setILine @settings[ 'interaction.blink_string' ]
      sleep @settings[ 'interaction.blink_duration' ]
      setILine message if message
    end

    # choices should be an array of CHOICE_* constants.
    # default is what is returned when Enter is pressed.
    def getChoice( prompt, choices, default = nil )
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

      if default.nil?
        showMessage msg
      else
        setILine msg
      end

      c = nil
      while retval.nil?
        c = @win_interaction.getch

        case c
        when Curses::KEY_NPAGE
          pageDown
        when Curses::KEY_PPAGE
          pageUp
        else
          if @message_expiry and Time.now < @message_expiry
            interactionBlink
            showMessage msg
          else
            case c
            when ENTER
              retval = default
            when ?0..?9
              if @choice_iterations < 1
                @choice_iterations = ( c - ?0 )
              else
                @choice_iterations = @choice_iterations * 10 + ( c - ?0 )
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
              interactionBlink( msg )
            end
          end
        end
      end

      terminateMessage
      setILine

      if @choice_iterations > 0
        @choice_iterations -= 1
        @iterated_choice = retval
        @do_display = false
      end

      retval
    end

  end
end