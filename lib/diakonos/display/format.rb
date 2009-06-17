module Diakonos
  module Display
    def self.to_colour_constant( str )
      case str.downcase
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
        str.to_i
      end
    end

    def self.to_formatting( str )
      formatting = Curses::A_NORMAL

      str.split( /\s+/ ).each do |format|
        colour_number = format.to_i
        if colour_number > Curses::COLOR_WHITE
          formatting |= Curses::color_pair( colour_number )
        elsif format.downcase == 'normal'
          formatting = Curses::A_NORMAL
        else
          formatting |= case format.downcase
          when "black", "0"
            Curses::color_pair( Curses::COLOR_BLACK )
          when "red", "1"
            Curses::color_pair( Curses::COLOR_RED )
          when "green", "2"
            Curses::color_pair( Curses::COLOR_GREEN )
          when "yellow", "brown", "3"
            Curses::color_pair( Curses::COLOR_YELLOW )
          when "blue", "4"
            Curses::color_pair( Curses::COLOR_BLUE )
          when "magenta", "purple", "5"
            Curses::color_pair( Curses::COLOR_MAGENTA )
          when "cyan", "6"
            Curses::color_pair( Curses::COLOR_CYAN )
          when "white", "7"
            Curses::color_pair( Curses::COLOR_WHITE )
          when "standout", "s", "so"
            Curses::A_STANDOUT
          when "underline", "u", "un", "ul"
            Curses::A_UNDERLINE
          when "reverse", "r", "rev", "inverse", "i", "inv"
            Curses::A_REVERSE
          when "blink", "bl", "blinking"
            Curses::A_BLINK
          when "dim", "d"
            Curses::A_DIM
          when "bold", "b", "bo"
            Curses::A_BOLD
          else
            0
          end
        end
      end

      formatting
    end

  end
end