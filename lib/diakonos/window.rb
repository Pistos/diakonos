module Diakonos
  class Window < ::Curses::Window

    if $diakonos.testing

      def initialize( *args )
        # Setup some variables to keep track of a fake cursor
        @row, @col = 0, 0
        super
        Curses::close_screen
      end

      def refresh
        # Don't refresh when testing
      end

      def setpos( row, col )
        @row, @col = row, col
      end

      def addstr( str )
        @col += str.length
      end

      def curx
        @col
      end

      def cury
        @row
      end

      def attrset( *args )
        # noop
      end
    end

  end
end