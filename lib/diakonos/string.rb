class String
    def subHome
      gsub( /~/, ENV[ "HOME" ] )
    end

    def keyCode
      retval = nil
      case downcase
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
        retval = Diakonos::BACKSPACE
      when "tab"
        retval = 9
      when "pageup", "page-up"
        retval = Curses::KEY_PPAGE
      when "pagedown", "page-down"
        retval = Curses::KEY_NPAGE
      when "enter", "return"
        retval = Diakonos::ENTER
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
        retval = Diakonos::ESCAPE
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
        retval = downcase[ -1 ].ord - 96
      when /^ctrl\+h$/
        retval = Diakonos::CTRL_H
      when /^alt\+(.)$/
        retval = [ Diakonos::ESCAPE, $1[ 0 ].ord ]
      when /^ctrl\+alt\+(.)$/, /^alt\+ctrl\+(.)$/
        retval = [ Diakonos::ESCAPE, downcase[ -1 ].ord - 96 ]
      when /^keycode(\d+)$/
        retval = $1.to_i
      when /^.$/
        retval = self[ 0 ].ord
      end
      if retval.class != Array
        retval = [ retval ]
      end
      retval
    end

    def toFormatting
      formatting = Curses::A_NORMAL
      split( /\s+/ ).each do |format|
        case format.downcase
        when "normal"
          formatting = Curses::A_NORMAL
        when "black", "0"
          formatting = formatting | Curses::color_pair( Curses::COLOR_BLACK )
        when "red", "1"
          formatting = formatting | Curses::color_pair( Curses::COLOR_RED )
        when "green", "2"
          formatting = formatting | Curses::color_pair( Curses::COLOR_GREEN )
        when "yellow", "brown", "3"
          formatting = formatting | Curses::color_pair( Curses::COLOR_YELLOW )
        when "blue", "4"
          formatting = formatting | Curses::color_pair( Curses::COLOR_BLUE )
        when "magenta", "purple", "5"
          formatting = formatting | Curses::color_pair( Curses::COLOR_MAGENTA )
        when "cyan", "6"
          formatting = formatting | Curses::color_pair( Curses::COLOR_CYAN )
        when "white", "7"
          formatting = formatting | Curses::color_pair( Curses::COLOR_WHITE )
        when "standout", "s", "so"
          formatting = formatting | Curses::A_STANDOUT
        when "underline", "u", "un", "ul"
          formatting = formatting | Curses::A_UNDERLINE
        when "reverse", "r", "rev", "inverse", "i", "inv"
          formatting = formatting | Curses::A_REVERSE
        when "blink", "bl", "blinking"
          formatting = formatting | Curses::A_BLINK
        when "dim", "d"
          formatting = formatting | Curses::A_DIM
        when "bold", "b", "bo"
          formatting = formatting | Curses::A_BOLD
        else
          if ( colour_number = format.to_i ) > Curses::COLOR_WHITE
            formatting = formatting | Curses::color_pair( colour_number )
          end
        end
      end
      formatting
    end

    def toColourConstant
      case downcase
        when "black", "0"
          Curses::COLOR_BLACK
        when "red", "1"
          Curses::COLOR_RED
        when "green", "2"
          Curses::COLOR_GREEN
        when "yellow", "brown", "3"
          Curses::COLOR_YELLOW
        when "blue", "4"
          Curses::COLOR_BLUE
        when "magenta", "purple", "5"
          Curses::COLOR_MAGENTA
        when "cyan", "6"
          Curses::COLOR_CYAN
        when "white", "7"
          Curses::COLOR_WHITE
        else
          to_i
      end
    end

    def toDirection( default = :down )
      direction = nil
      case self
      when "up"
        direction = :up
      when /other/
        direction = :opposite
      when "down"
        direction = :down
      when "forward"
        direction = :forward
      when "backward"
        direction = :backward
      else
        direction = default
      end
      direction
    end

    def to_a
      [ self ]
    end

    def to_b
      case downcase
      when "true", "t", "1", "yes", "y", "on", "+"
        true
      else
        false
      end
    end

    def indentation_level( indent_size, indent_roundup, tab_size = Diakonos::DEFAULT_TAB_SIZE, indent_ignore_charset = nil )
      if indent_ignore_charset.nil?
        level = 0
        if self =~ /^([\s]+)/
          whitespace = $1.expandTabs( tab_size )
          level = whitespace.length / indent_size
          if indent_roundup and ( whitespace.length % indent_size > 0 )
            level += 1
          end
        end
      else
        if self =~ /^[\s#{indent_ignore_charset}]*$/ or self == ""
          level = -1
        elsif self =~ /^([\s#{indent_ignore_charset}]+)/
          whitespace = $1.expandTabs( tab_size )
          level = whitespace.length / indent_size
          if indent_roundup and ( whitespace.length % indent_size > 0 )
            level += 1
          end
        else
          level = 0
        end
      end

      level
    end

    def expandTabs( tab_size = Diakonos::DEFAULT_TAB_SIZE )
      s = dup
      while s.sub!( /\t/ ) { |match_text|
        match = Regexp.last_match
        index = match.begin( 0 )
        # Return value for block:
        " " * ( tab_size - ( index % tab_size ) )
      }
      end
      s
    end

    def newlineSplit
      retval = split( /\\n/ )
      if self =~ /\\n$/
        retval << ""
      end
      if retval.length > 1
        retval[ 0 ] << "$"
        retval[ 1..-2 ].collect do |el|
          "^" << el << "$"
        end
        retval[ -1 ] = "^" << retval[ -1 ]
      end
      retval
    end

    # Works like normal String#index except returns the index
    # of the first matching regexp group if one or more groups are specified
    # in the regexp. Both the index and the matched text are returned.
    def group_index( regexp, offset = 0 )
      if regexp.class != Regexp
        return index( regexp, offset )
      end

      i = nil
      match_text = nil
      working_offset = 0
      loop do
        index( regexp, working_offset )
        match = Regexp.last_match
        if match
          i = match.begin( 0 )
          match_text = match[ 0 ]
          if match.length > 1
            # Find first matching group
            1.upto( match.length - 1 ) do |match_item_index|
              if match[ match_item_index ]
                i = match.begin( match_item_index )
                match_text = match[ match_item_index ]
                break
              end
            end
          end

          break if i >= offset
        else
          i = nil
          break
        end
        working_offset += 1
      end

      [ i, match_text ]
    end

    # Works like normal String#rindex except returns the index
    # of the first matching regexp group if one or more groups are specified
    # in the regexp. Both the index and the matched text are returned.
    def group_rindex( regexp, offset = length )
      if regexp.class != Regexp
        return rindex( regexp, offset )
      end

      i = nil
      match_text = nil
      working_offset = length
      loop do
        rindex( regexp, working_offset )
        match = Regexp.last_match
        if match
          i = match.end( 0 ) - 1
          match_text = match[ 0 ]
          if match.length > 1
            # Find first matching group
            1.upto( match.length - 1 ) do |match_item_index|
              if match[ match_item_index ]
                i = match.end( match_item_index ) - 1
                match_text = match[ match_item_index ]
                break
              end
            end
          end

          if match_text == ""
            # Assume that an empty string means that it matched $
            i += 1
          end

          break if i <= offset
        else
          i = nil
          break
        end
        working_offset -= 1
      end

      [ i, match_text ]
    end

    def movement?
      self =~ /^((cursor|page|scroll)(Up|Down|Left|Right)|find)/
    end

    # Backport of Ruby 1.9's String#ord into Ruby 1.8
    if ! method_defined?( :ord )
      def ord
        self[ 0 ]
      end
    end
end

