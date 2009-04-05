module Diakonos
  module Display

    def self.to_formatting( str )
      formatting = Curses::A_NORMAL
      str.split( /\s+/ ).each do |format|
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

  end
end