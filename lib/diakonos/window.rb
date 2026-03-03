module Diakonos
  class Window < ::Curses::Window

    if ENV['DIAKONOS_TESTING']

      def initialize( *args )
        # Set up some variables to keep track of a fake cursor
        @row, @col = 0, 0
        @fb_height = args[0] || 0
        @fb_width = args[1] || 0
        super
        Curses.close_screen
      end

      def addstr( str )
        if $use_virtual_screen && @framebuffer
          str.each_char do |ch|
            if @row >= 0 && @row < @fb_height && @col >= 0 && @col < @fb_width
              @framebuffer[@row][@col] = ch
            end
            @col += 1
          end
        else
          @col += str.length
        end
      end

      def attron( *_args )
        yield
      end

      def attrset( *args )
        # noop
      end

      def close
        # noop
      end

      def curx
        @col
      end

      def cury
        @row
      end

      def getch
        $keystrokes.shift
      end

      def refresh
        # noop
      end

      def reset_virtual_screen(height: nil, width: nil)
        @fb_height = height if height
        @fb_width = width if width

        @framebuffer = Array.new(@fb_height) { ' ' * @fb_width }
      end

      def setpos( row, col )
        @row, @col = row, col
      end

      def virtual_screen
        @framebuffer&.map(&:dup)
      end

    end

  end
end
