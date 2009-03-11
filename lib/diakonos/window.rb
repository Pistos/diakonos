module Diakonos

  class Window < ::Curses::Window

    def refresh
      return  if $diakonos.nil? || $diakonos.testing
      super
    end

    def puts( string = "" )
      addstr( string + "\n" )
    end

  end

end