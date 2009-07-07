module Diakonos
  module Keying

    KEYSTRINGS = [
        "ctrl+space",   # 0
        "ctrl+a",       # 1
        "ctrl+b",       # 2
        "ctrl+c",       # 3
        "ctrl+d",       # 4
        "ctrl+e",       # 5
        "ctrl+f",       # 6
        "ctrl+g",       # 7
        nil,            # 8
        "tab",          # 9
        "ctrl+j",       # 10
        "ctrl+k",       # 11
        "ctrl+l",       # 12
        "enter",        # 13
        "ctrl+n",       # 14
        "ctrl+o",       # 15
        "ctrl+p",       # 16
        "ctrl+q",       # 17
        "ctrl+r",       # 18
        "ctrl+s",       # 19
        "ctrl+t",       # 20
        "ctrl+u",       # 21
        "ctrl+v",       # 22
        "ctrl+w",       # 23
        "ctrl+x",       # 24
        "ctrl+y",       # 25
        "ctrl+z",       # 26
        "esc",          # 27
        nil,            # 28
        nil,            # 29
        nil,            # 30
        nil,            # 31
        "space",        # 32
        33.chr, 34.chr, 35.chr, 36.chr, 37.chr, 38.chr, 39.chr,
        40.chr, 41.chr, 42.chr, 43.chr, 44.chr, 45.chr, 46.chr, 47.chr, 48.chr, 49.chr,
        50.chr, 51.chr, 52.chr, 53.chr, 54.chr, 55.chr, 56.chr, 57.chr, 58.chr, 59.chr,
        60.chr, 61.chr, 62.chr, 63.chr, 64.chr, 65.chr, 66.chr, 67.chr, 68.chr, 69.chr,
        70.chr, 71.chr, 72.chr, 73.chr, 74.chr, 75.chr, 76.chr, 77.chr, 78.chr, 79.chr,
        80.chr, 81.chr, 82.chr, 83.chr, 84.chr, 85.chr, 86.chr, 87.chr, 88.chr, 89.chr,
        90.chr, 91.chr, 92.chr, 93.chr, 94.chr, 95.chr, 96.chr, 97.chr, 98.chr, 99.chr,
        100.chr, 101.chr, 102.chr, 103.chr, 104.chr, 105.chr, 106.chr, 107.chr, 108.chr, 109.chr,
        110.chr, 111.chr, 112.chr, 113.chr, 114.chr, 115.chr, 116.chr, 117.chr, 118.chr, 119.chr,
        120.chr, 121.chr, 122.chr, 123.chr, 124.chr, 125.chr, 126.chr,
        "backspace"    # 127
    ]

    def self.keycodes_for( str )
      retval = case str.downcase
      when "down"
        Curses::KEY_DOWN
      when "up"
        Curses::KEY_UP
      when "left"
        Curses::KEY_LEFT
      when "right"
        Curses::KEY_RIGHT
      when "home"
        Curses::KEY_HOME
      when "end"
        Curses::KEY_END
      when "insert", "ins"
        Curses::KEY_IC
      when "delete", "del"
        Curses::KEY_DC
      when "backspace"
        ::Diakonos::BACKSPACE
      when "tab"
        9
      when "pageup", "page-up"
        Curses::KEY_PPAGE
      when "pagedown", "page-down"
        Curses::KEY_NPAGE
      when "enter", "return"
        ::Diakonos::ENTER
      when "numpad7", "keypad7", "kp-7"
        Curses::KEY_A1
      when "numpad9", "keypad9", "kp-9"
        Curses::KEY_A3
      when "numpad5", "keypad5", "kp-5"
        Curses::KEY_B2
      when "numpad1", "keypad1", "kp-1"
        Curses::KEY_C1
      when "numpad3", "keypad3", "kp-3"
        Curses::KEY_C3
      when "escape", "esc"
        ::Diakonos::ESCAPE
      when "space"
        32
      when "ctrl+space"
        0
      when "find"
        Curses::KEY_FIND
      when "select"
        Curses::KEY_SELECT
      when "suspend"
        Curses::KEY_SUSPEND
      when /^f(\d\d?)$/
        Curses::KEY_F0 + $1.to_i
      when /^ctrl\+[a-gi-z]$/
        str.downcase[ -1 ].ord - 96
      when /^ctrl\+h$/
        ::Diakonos::CTRL_H
      when /^alt\+(.)$/
        [ ::Diakonos::ESCAPE, $1[ 0 ].ord ]
      when /^ctrl\+alt\+(.)$/, /^alt\+ctrl\+(.)$/
        [ ::Diakonos::ESCAPE, str.downcase[ -1 ].ord - 96 ]
      when /^keycode(\d+)$/
        $1.to_i
      when /^.$/
        str[ 0 ].ord
      end
      Array( retval )
    end

    def self.key_string_for( num )
      retval = KEYSTRINGS[ num ]
      if retval.nil?
        retval = case num
        when Curses::KEY_DOWN
          "down"
        when Curses::KEY_UP
          "up"
        when Curses::KEY_LEFT
          "left"
        when Curses::KEY_RIGHT
          "right"
        when Curses::KEY_HOME
          "home"
        when Curses::KEY_END
          "end"
        when Curses::KEY_IC
          "insert"
        when Curses::KEY_DC
          "delete"
        when Curses::KEY_PPAGE
          "page-up"
        when Curses::KEY_NPAGE
          "page-down"
        when Curses::KEY_A1
          "numpad7"
        when Curses::KEY_A3
          "numpad9"
        when Curses::KEY_B2
          "numpad5"
        when Curses::KEY_C1
          "numpad1"
        when Curses::KEY_C3
          "numpad3"
        when Curses::KEY_FIND
          "find"
        when Curses::KEY_SELECT
          "select"
        when Curses::KEY_SUSPEND
          "suspend"
        when Curses::KEY_F0..(Curses::KEY_F0 + 24)
          "f" + ( num - Curses::KEY_F0 ).to_s
        when CTRL_H
          "ctrl+h"
        when Curses::KEY_RESIZE
          "resize"
        when RESIZE2
          "resize2"
        end
      end
      if retval.nil? && num.class == Fixnum
        retval = "keycode#{num}"
      end
      retval
    end
  end

  class Diakonos
    def keychain_str_for( array )
      chain_str = ""
      array.each do |key|
        key_str = Keying.key_string_for( key )
        if key_str
          chain_str << key_str + " "
        else
          chain_str << key.to_s + " "
        end
      end
      chain_str.strip
    end

    def capture_keychain( c, context )
      if c == ENTER
        @capturing_keychain = false
        @current_buffer.delete_selection
        str = keychain_str_for( context )
        @current_buffer.insert_string str
        cursor_right( Buffer::STILL_TYPING, str.length )
      else
        keychain_pressed = context.concat [ c ]

        function_and_args = @modes[ 'edit' ].keymap.get_leaf( keychain_pressed )

        if function_and_args
          function, args = function_and_args
        end

        partial_keychain = @modes[ 'edit' ].keymap.get_node( keychain_pressed )
        if partial_keychain
          set_iline( "Part of existing keychain: " + keychain_str_for( keychain_pressed ) + "..." )
        else
          set_iline keychain_str_for( keychain_pressed ) + "..."
        end
        process_keystroke keychain_pressed
      end
    end

    def capture_mapping( c, context )
      if c == ENTER
        @capturing_mapping = false
        @current_buffer.delete_selection
        set_iline
      else
        keychain_pressed = context.concat [ c ]

        function_and_args = @modes[ 'edit' ].keymap.get_leaf( keychain_pressed )

        if function_and_args
          function, args = function_and_args
          set_iline "#{keychain_str_for( keychain_pressed )}  ->  #{function}( #{args} )"
        else
          partial_keychain = @modes[ 'edit' ].keymap.get_node( keychain_pressed )
          if partial_keychain
            set_iline( "Several mappings start with: " + keychain_str_for( keychain_pressed ) + "..." )
            process_keystroke keychain_pressed
          else
            set_iline "There is no mapping for " + keychain_str_for( keychain_pressed )
          end
        end
      end
    end

    def typeable?( char )
      char > 31 && char < 255 && char != BACKSPACE
    end

    # context is an array of characters (bytes) which are keystrokes previously
    # typed (in a chain of keystrokes)
    def process_keystroke( context = [], mode = 'edit', ch = nil )
      ch ||= @modes[ mode ].window.getch
      return  if ch.nil?
      c = ch.ord

      if @capturing_keychain
        capture_keychain c, context
      elsif @capturing_mapping
        capture_mapping c, context
      else

        if context.empty? && typeable?( c )
          if @macro_history
            @macro_history.push "type_character #{c}, #{mode.inspect}"
          end
          @there_was_non_movement = true
          type_character c, mode

          # Handle X windows paste
          s = ""
          loop do
            ch = nil
            begin
              Timeout::timeout( 0.02 ) do
                ch = @modes[ mode ].window.getch
              end
            rescue Timeout::Error => e
              break
            end
            break  if ch.nil?

            c = ch.ord
            if typeable?( c )
              s << c
            elsif c == ENTER
              s << "\n"
            else
              break
            end
          end

          if ! s.empty?
            case mode
            when 'edit'
              @current_buffer.paste s
            when 'input'
              @readline.paste s
            end
          end

          if ch
            process_keystroke( [], mode, ch )
          end

          return
        end
        keychain_pressed = context.concat [ c ]

        function_and_args = @modes[ mode ].keymap.get_leaf( keychain_pressed )

        if function_and_args
          function, args = function_and_args
          if mode != 'input' && ! @settings[ "context.combined" ]
            set_iline
          end

          if args
            formatted_function = "#{function}( #{args} )"
          else
            formatted_function = function
          end

          if @macro_history
            @macro_history.push formatted_function
          end

          begin
            self.send function, *args

            @last_commands << formatted_function  unless formatted_function == "repeat_last"
            if ! @there_was_non_movement
              @there_was_non_movement = !( /^((cursor|page|scroll)(Up|Down|Left|Right)|find)/ === formatted_function )
            end
          rescue Exception => e
            debug_log e.message
            debug_log e.backtrace.join( "\n\t" )
            show_exception e
          end
        else
          partial_keychain = @modes[ mode ].keymap.get_node( keychain_pressed )
          if partial_keychain
            if mode != 'input'
              set_iline( keychain_str_for( keychain_pressed ) + "..." )
            end
            process_keystroke keychain_pressed, mode
          elsif mode != 'input'
            set_iline "Nothing assigned to #{keychain_str_for( keychain_pressed )}"
          end
        end
      end
    end

    def type_character( c, mode = 'edit' )
      case mode
      when 'edit'
        @current_buffer.delete_selection Buffer::DONT_DISPLAY
        @current_buffer.insert_char c
        cursor_right Buffer::STILL_TYPING
      when 'input'
        if @readline.numbered_list?
          if(
            showing_list? &&
            ( (48..57).include?( c ) || (97..122).include?( c ) )
          )
            line = list_buffer.to_a.select { |l|
              l =~ /^#{c.chr}  /
            }[ 0 ]

            if line
              list_sync line
              @readline.finish
            end
          end
        else
          @readline.handle_typeable c
        end
      end
    end

  end
end
