module Diakonos
  module Keying
    def self.keycode_for( str )
      retval = nil
      case str.downcase
      when "down"
        retval = Curses::KEY_DOWN
      when "up"
        retval = Curses::KEY_UP
      when "left"
        retval = Curses::KEY_LEFT
      when "right"
        retval = Curses::KEY_RIGHT
      when "home"
        retval = Curses::KEY_HOME
      when "end"
        retval = Curses::KEY_END
      when "insert", "ins"
        retval = Curses::KEY_IC
      when "delete", "del"
        retval = Curses::KEY_DC
      when "backspace"
        retval = ::Diakonos::BACKSPACE
      when "tab"
        retval = 9
      when "pageup", "page-up"
        retval = Curses::KEY_PPAGE
      when "pagedown", "page-down"
        retval = Curses::KEY_NPAGE
      when "enter", "return"
        retval = ::Diakonos::ENTER
      when "numpad7", "keypad7", "kp-7"
        retval = Curses::KEY_A1
      when "numpad9", "keypad9", "kp-9"
        retval = Curses::KEY_A3
      when "numpad5", "keypad5", "kp-5"
        retval = Curses::KEY_B2
      when "numpad1", "keypad1", "kp-1"
        retval = Curses::KEY_C1
      when "numpad3", "keypad3", "kp-3"
        retval = Curses::KEY_C3
      when "escape", "esc"
        retval = ::Diakonos::ESCAPE
      when "space"
        retval = 32
      when "ctrl+space"
        retval = 0
      when "find"
        retval = Curses::KEY_FIND
      when "select"
        retval = Curses::KEY_SELECT
      when "suspend"
        retval = Curses::KEY_SUSPEND
      when /^f(\d\d?)$/
        retval = Curses::KEY_F0 + $1.to_i
      when /^ctrl\+[a-gi-z]$/
        retval = str.downcase[ -1 ].ord - 96
      when /^ctrl\+h$/
        retval = ::Diakonos::CTRL_H
      when /^alt\+(.)$/
        retval = [ ::Diakonos::ESCAPE, $1[ 0 ].ord ]
      when /^ctrl\+alt\+(.)$/, /^alt\+ctrl\+(.)$/
        retval = [ ::Diakonos::ESCAPE, str.downcase[ -1 ].ord - 96 ]
      when /^keycode(\d+)$/
        retval = $1.to_i
      when /^.$/
        retval = str[ 0 ].ord
      end
      if retval.class != Array
        retval = [ retval ]
      end
      retval
    end
  end

  class Diakonos
    def capture_keychain( c, context )
      if c == ENTER
        @capturing_keychain = false
        @current_buffer.deleteSelection
        str = context.to_keychain_s.strip
        @current_buffer.insertString str
        cursorRight( Buffer::STILL_TYPING, str.length )
      else
        keychain_pressed = context.concat [ c ]

        function_and_args = @keychains.getLeaf( keychain_pressed )

        if function_and_args
          function, args = function_and_args
        end

        partial_keychain = @keychains.getNode( keychain_pressed )
        if partial_keychain
          setILine( "Part of existing keychain: " + keychain_pressed.to_keychain_s + "..." )
        else
          setILine keychain_pressed.to_keychain_s + "..."
        end
        processKeystroke( keychain_pressed )
      end
    end

    def capture_mapping( c, context )
      if c == ENTER
        @capturing_mapping = false
        @current_buffer.deleteSelection
        setILine
      else
        keychain_pressed = context.concat [ c ]

        function_and_args = @keychains.getLeaf( keychain_pressed )

        if function_and_args
          function, args = function_and_args
          setILine "#{keychain_pressed.to_keychain_s.strip}  ->  #{function}( #{args} )"
        else
          partial_keychain = @keychains.getNode( keychain_pressed )
          if partial_keychain
            setILine( "Several mappings start with: " + keychain_pressed.to_keychain_s + "..." )
            processKeystroke( keychain_pressed )
          else
            setILine "There is no mapping for " + keychain_pressed.to_keychain_s
          end
        end
      end
    end

    # context is an array of characters (bytes) which are keystrokes previously
    # typed (in a chain of keystrokes)
    def processKeystroke( context = [] )
      c = @win_main.getch.ord

      if @capturing_keychain
        capture_keychain c, context
      elsif @capturing_mapping
        capture_mapping c, context
      else

        if context.empty?
          if c > 31 and c < 255 and c != BACKSPACE
            if @macro_history
              @macro_history.push "typeCharacter #{c}"
            end
            @there_was_non_movement = true
            typeCharacter c
            return
          end
        end
        keychain_pressed = context.concat [ c ]

        function_and_args = @keychains.getLeaf( keychain_pressed )

        if function_and_args
          function, args = function_and_args
          setILine if not @settings[ "context.combined" ]

          if args
            to_eval = "#{function}( #{args} )"
          else
            to_eval = function
          end

          if @macro_history
            @macro_history.push to_eval
          end

          begin
            eval to_eval, nil, "eval"
            @last_commands << to_eval unless to_eval == "repeatLast"
            if not @there_was_non_movement
              @there_was_non_movement = ( not to_eval.movement? )
            end
          rescue Exception => e
            debugLog e.message
            debugLog e.backtrace.join( "\n\t" )
            showException e
          end
        else
          partial_keychain = @keychains.getNode( keychain_pressed )
          if partial_keychain
            setILine( keychain_pressed.to_keychain_s + "..." )
            processKeystroke( keychain_pressed )
          else
            setILine "Nothing assigned to #{keychain_pressed.to_keychain_s}"
          end
        end
      end
    end
    protected :processKeystroke

    def typeCharacter( c )
      @current_buffer.deleteSelection( Buffer::DONT_DISPLAY )
      @current_buffer.insertChar c
      cursorRight( Buffer::STILL_TYPING )
    end

  end
end