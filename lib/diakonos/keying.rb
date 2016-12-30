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
    ] + (33..126).map(&:chr) + [
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
      if retval.nil? && num.class == Integer
        retval = "keycode#{num}"
      end
      retval
    end

    UTF_8_2_BYTE_BEGIN = 0xc2
    UTF_8_2_BYTE_END = 0xdf
    UTF_8_3_BYTE_BEGIN = 0xe0
    UTF_8_3_BYTE_END = 0xef
    UTF_8_4_BYTE_BEGIN = 0xf0
    UTF_8_4_BYTE_END = 0xf4
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
        buffer_current.delete_selection
        str = keychain_str_for( context )
        buffer_current.insert_string str
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
        buffer_current.delete_selection
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

    # @param [Integer] c The first byte of a UTF-8 byte sequence
    # @return [String] nil if c is not the beginning of a multi-byte sequence
    def utf_8_bytes_to_char(c, mode)
      if Keying::UTF_8_2_BYTE_BEGIN <= c && c <= Keying::UTF_8_2_BYTE_END
        # 2-byte character
        byte_array = [c, @modes[mode].window.getch.ord]
      elsif Keying::UTF_8_3_BYTE_BEGIN <= c && c <= Keying::UTF_8_3_BYTE_END
        # 3-byte character
        byte_array = [
          c,
          @modes[mode].window.getch.ord,
          @modes[mode].window.getch.ord,
        ]
      elsif Keying::UTF_8_4_BYTE_BEGIN <= c && c <= Keying::UTF_8_4_BYTE_END
        # 4-byte character
        byte_array = [
          c,
          @modes[mode].window.getch.ord,
          @modes[mode].window.getch.ord,
          @modes[mode].window.getch.ord,
        ]
      else
        return nil
      end

      byte_array.pack('C*').force_encoding('utf-8')
    end

    # @param [Integer] c The ordinal (number) of a character
    # @param [String] mode
    # @return [Boolean] true iff c began a UTF-8 byte sequence
    def handle_utf_8(c, mode)
      utf_8_char = utf_8_bytes_to_char(c, mode)
      if utf_8_char
        self.type_character utf_8_char, mode
        true
      end
    end

    # Handle paste from a GUI (like x.org).  i.e. Shift-Insert
    def handle_gui_paste(mode)
      s = ""
      ch = nil

      loop do
        ch = nil
        begin
          Timeout::timeout(0.02) do
            ch = @modes[mode].window.getch
          end
        rescue Timeout::Error => e
          break
        end
        break  if ch.nil?

        c = ch.ord
        utf_8_char = self.utf_8_bytes_to_char(c, mode)

        if utf_8_char
          s << utf_8_char
        elsif self.typeable?(c)
          s << c
        elsif c == ENTER && mode == 'edit'
          s << "\n"
        else
          break
        end
      end

      if ! s.empty?
        case mode
        when 'edit'
          buffer_current.paste s, Buffer::TYPING
        when 'input'
          @readline.paste s
        end
      end

      if ch
        process_keystroke( [], mode, ch )
      end
    end

    # context is an array of characters (bytes) which are keystrokes previously
    # typed (in a chain of keystrokes)
    def process_keystroke( context = [], mode = 'edit', ch = nil )
      ch ||= @modes[ mode ].window.getch
      return  if ch.nil?

      if ch == Curses::KEY_MOUSE
        handle_mouse_event
        return
      end

      c = ch.ord

      self.handle_utf_8(c, mode) and return

      if @capturing_keychain
        capture_keychain c, context
      elsif @capturing_mapping
        capture_mapping c, context
      else

        if context.empty? && typeable?( c )
          self.type_character ch, mode
          self.handle_gui_paste(mode)
          return
        end

        keychain_pressed = context.concat [ c ]

        function_and_args = (
          @modes[mode].keymap_after[@function_last].get_leaf( keychain_pressed ) ||
          @modes[mode].keymap.get_leaf( keychain_pressed )
        )

        if function_and_args
          function, args = function_and_args
          @function_last = function

          if mode != 'input' && ! @settings[ "context.combined" ]
            set_iline
          end

          if args
            to_eval = "#{function}( #{args} )"
          else
            to_eval = function
          end

          if @macro_history
            @macro_history.push to_eval
          end

          begin
            if buffer_current.search_area? && ! ( /^(?:find|readline)/ === to_eval )
              buffer_current.clear_search_area
            end
            eval to_eval, nil, "eval"
            @functions_last << to_eval  unless to_eval == "repeat_last"
            if ! @there_was_non_movement
              @there_was_non_movement = !( /^((cursor|page|scroll)_?(up|down|left|right)|find|seek)/i === to_eval )
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
      if @macro_history
        @macro_history.push "type_character #{c.inspect}, #{mode.inspect}"
      end
      @there_was_non_movement = true

      case mode
      when 'edit'
        buffer_current.delete_selection Buffer::DONT_DISPLAY
        buffer_current.insert_string c
        cursor_right Buffer::STILL_TYPING
        if c =~ @indent_triggers[buffer_current.language]
          buffer_current.parsed_indent cursor_eol: true
        end
      when 'input'
        if ! @readline.numbered_list?
          @readline.paste c
        else
          if(
            showing_list? &&
            ( (48..57).include?( c.ord ) || (97..122).include?( c.ord ) )
          )
            line = list_buffer.to_a.select { |l|
              l =~ /^#{c}  /
            }[ 0 ]

            if line
              @readline.list_sync line
              @readline.finish
            end
          end
        end
      end
    end

  end
end
