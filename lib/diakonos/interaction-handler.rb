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

  # TODO: Turn the CHOICE_* constants into one or more Hashes?

  CHOICE_NO           = 0
  CHOICE_YES          = 1
  CHOICE_ALL          = 2
  CHOICE_CANCEL       = 3
  CHOICE_YES_TO_ALL   = 4
  CHOICE_NO_TO_ALL    = 5
  CHOICE_YES_AND_STOP = 6
  CHOICE_DELETE       = 7
  CHOICE_WITHIN_SELECTION = 8

  class InteractionHandler
    CHOICE_STRINGS = [
      '(n)o',
      '(y)es',
      '(a)ll',
      '(c)ancel',
      'y(e)s to all',
      'n(o) to all',
      'yes and (s)top',
      '(d)elete',
      'all (w)ithin selection',
    ]
    CHOICE_KEYS = [
      ["n".ord, "N".ord],
      ["y".ord, "Y".ord],
      ["a".ord, "A".ord],
      ["c".ord, "C".ord, ESCAPE, CTRL_C, CTRL_D, CTRL_Q],
      ["e".ord],
      ["o".ord],
      ["s".ord],
      ["d".ord],
      ["w".ord],
    ]

    # TODO: Move win_interaction creation, etc. into this class.
    #       If necessary, expose it with attr_reader
    #       e.g. for @modes[ 'input' ].window = @win_interaction
    def initialize(
      win_main:,
      win_interaction:,
      cursor_manager:,
      testing: false
    )
      @win_main = win_main
      @win_interaction = win_interaction
      @cursor_manager = cursor_manager
      @testing = testing

      @choice_iterations = 0
    end

    # Display text on the interaction line.
    def set_iline(string = "")
      return 0  if @testing
      return 0  if $diakonos.readline

      @iline = string
      Curses::curs_set 0
      @win_interaction.setpos( 0, 0 )
      @win_interaction.addstr( "%-#{Curses::cols}s" % @iline )
      @win_interaction.refresh
      Curses::curs_set 1
      string.length
    end

    def set_iline_if_empty(string)
      if @iline.nil? || @iline.empty?
        set_iline string
      end
    end

    def get_char(prompt)
      set_iline prompt
      char = @win_main.getch
      set_iline
      char
    end

    # choices should be an array of CHOICE_* constants.
    # default is what is returned when Enter is pressed.
    def get_choice( prompt, choices, default = nil )
      retval = @iterated_choice
      if retval
        @choice_iterations -= 1
        if @choice_iterations < 1
          @iterated_choice = nil
          $diakonos.do_display = true
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

      while retval.nil?
        ch = @win_interaction.getch
        if ch
          c = ch.ord
        else
          next
        end

        case c
        when Curses::KEY_NPAGE
          @cursor_manager.page_down
        when Curses::KEY_PPAGE
          @cursor_manager.page_up
        else
          if @message_expiry && Time.now < @message_expiry
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
        $diakonos.do_display = false
      end

      retval
    end

    private

    def show_message( message, non_interaction_duration = @settings[ 'interaction.choice_delay' ] )
      terminate_message

      @message_expiry = Time.now + non_interaction_duration
      @message_thread = Thread.new do
        time_left = @message_expiry - Time.now
        while time_left > 0
          set_iline "(#{time_left.round}) #{message}"
          @win_main.setpos( @saved_main_y, @saved_main_x )
          sleep 1
          time_left = @message_expiry - Time.now
        end
        set_iline message
        @win_main.setpos( @saved_main_y, @saved_main_x )
      end
    end

    def terminate_message
      if @message_thread && @message_thread.alive?
        @message_thread.terminate
        @message_thread = nil
      end
    end

    def interaction_blink( message = nil )
      terminate_message
      set_iline @settings[ 'interaction.blink_string' ]
      sleep @settings[ 'interaction.blink_duration' ]
      set_iline message if message
    end
  end
end