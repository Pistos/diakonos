module Diakonos

  class Window < ::Curses::Window

    def refresh
      return  if $diakonos.nil? || $diakonos.testing
      super
    end

    def puts( string = "" )
      addstr( string + "\n" )
    end

    # setpos, but with some boundary checks
    def setpos_( y, x )
      $diakonos.debugLog "setpos: y < 0 (#{y})" if y < 0
      $diakonos.debugLog "setpos: x < 0 (#{x})" if x < 0
      $diakonos.debugLog "setpos: y > lines (#{y})" if y > Curses::lines
      $diakonos.debugLog "setpos: x > cols (#{x})" if x > Curses::cols
      setpos( y, x )
    end

    def addstr_( string )
      x = curx
      y = cury
      x2 = curx + string.length

      if y < 0 or x < 0 or y > Curses::lines or x > Curses::cols or x2 < 0 or x2 > Curses::cols
        begin
          raise Exception
        rescue Exception => e
          $diakonos.debugLog e.backtrace[ 1 ]
          $diakonos.debugLog e.backtrace[ 2 ]
        end
      end

      addstr( string )
    end

  end

end