module Diakonos

  class Readline

    attr_reader :input

    # completion_array is the array of strings that tab completion can use
    # The block returns true if a refresh is needed?
    # @param options :initial_text, :completion_array, :history, :do_complete, :on_dirs
    def initialize( diakonos, window, start_pos, options = {}, &block )
      @diakonos = diakonos
      @window = window
      @start_pos = start_pos
      @window.setpos( 0, start_pos )
      @initial_text = options[ :initial_text ] || ''
      @completion_array = options[ :completion_array ]
      @list_filename = @diakonos.list_filename

      @history = options[ :history ] || []
      @history << @initial_text
      @history_index = [ @history.length - 1, 0 ].max

      @do_complete = options[ :do_complete ] || ::Diakonos::DONT_COMPLETE
      @on_dirs = options[ :on_dirs ] || :go_into_dirs
      @numbered_list = options[ :numbered_list ]

      @block = block

      # ---

      @input = @initial_text.dup
      if ! @input.empty?
        call_block
      end

      @icurx = @window.curx
      @icury = @window.cury
      @view_y = 0
      @window.addstr @initial_text
      @input_cursor = @initial_text.length
      @opened_list_file = false

      if @do_complete
        complete_input
      end
    end

    def call_block
      if @block
        @block.call( @input )
        @window.refresh
      end
    end

    def set_input( input = '' )
      if numbered_list? && input =~ /^\w  /
        input = input[ 3..-1 ]
      end
      @input = input
    end

    def done?
      @done
    end

    def finish
      @done = true
    end

    def list_sync( line )
      return  if line.nil?
      set_input line
      cursor_write_input
    end

    def numbered_list?
      @numbered_list
    end

    def sync
      if @input_cursor > @input.length
        @input_cursor = @input.length
      elsif @input_cursor < @view_y
        @view_y = @input_cursor
      end
      @window.setpos( @window.cury, @start_pos + @input_cursor - @view_y )
      redraw_input
      call_block
    end

    def handle_typeable( c )
      paste c.chr
    end

    def paste( s )
      @input = @input[ 0...@input_cursor ] + s + @input[ @input_cursor..-1 ]
      @input_cursor += s.length
      diff = ( @input_cursor - @view_y ) + 1 - ( Curses::cols - @start_pos )
      if diff > 0
        @view_y += diff
      end
      sync
    end

    def redraw_input
      input = @input[ @view_y...(@view_y + Curses::cols) ]

      curx = @window.curx
      cury = @window.cury
      @window.setpos( @icury, @icurx )
      @window.addstr "%-#{ Curses::cols - curx }s%s" % [
        input,
        " " * [ ( Curses::cols - input.length ), 0 ].max
      ]
      @window.setpos( cury, curx )
      @window.refresh
    end

    # Redisplays the input text starting at the start of the user input area,
    # positioning the cursor at the end of the text.
    def cursor_write_input
      if @input
        @input_cursor = @input.length
        @window.setpos( @window.cury, @icurx + @input.length )
        redraw_input
      end
    end

    def complete_input
      if @completion_array && @input.length > 0
        len = @input.length
        matches = @completion_array.find_all { |el| el[ 0...len ] == @input && len <= el.length }
      else
        path = File.expand_path( @input )
        if FileTest.directory? path
          path << '/'
        end
        matches = Dir.glob( ( path + "*" ).gsub( /\*\*/, "*" ) )
        if @on_dirs == :accept_dirs
          matches = matches.select { |m| File.directory? m }
        end
      end
      matches.sort!

      if matches.length == 1
        @input = matches[ 0 ]
        cursor_write_input
        File.open( @list_filename, "w" ) do |f|
          if @completion_array.nil?
            f.puts "(unique)"
          else
            f.puts @input
          end
        end
        if @completion_array.nil? && FileTest.directory?( @input )
          @input << "/"
          cursor_write_input
          if @on_dirs != :accept_dirs
            complete_input
          end
        end
      elsif matches.length > 1
        common = matches[ 0 ]
        File.open( @list_filename, "w" ) do |f|
          i = nil
          matches.each do |match|
            f.print match
            if FileTest.directory?( match )
              f.print '/'
            end
            f.puts

            if match[ 0 ] != common[ 0 ]
              common = nil
              break
            end

            up_to = [ common.length - 1, match.length - 1 ].min
            i = 1
            while ( i <= up_to ) && ( match[ 0..i ] == common[ 0..i ] )
              i += 1
            end
            common = common[ 0...i ]
          end
        end
        if common.nil?
          File.open( @list_filename, "w" ) do |f|
            f.puts "(no matches)"
          end
        else
          @input = common
          cursor_write_input
        end
      else
        File.open( @list_filename, "w" ) do |f|
          f.puts "(no matches)"
        end
      end
      @diakonos.open_list_buffer
      @window.setpos( @window.cury, @window.curx )
    end

  end

end
