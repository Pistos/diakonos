module Diakonos

  class Readline

    # completion_array is the array of strings that tab completion can use
    # The block returns true if a refresh is needed?
    # @param options :initial_text, :completion_array, :history, :do_complete, :on_dirs
    def initialize( diakonos, window, prompt, options = {}, &block )
      @diakonos = diakonos
      @window = window
      @prompt = prompt
      pos = redraw_prompt
      @window.setpos( 0, pos )
      @initial_text = options[ :initial_text ] || ''
      @completion_array = options[ :completion_array ]
      @list_filename = @diakonos.list_filename

      @history = options[ :history ] || []
      @history << @initial_text
      @history_index = @history.length - 1

      @do_complete = options[ :do_complete ] || ::Diakonos::DONT_COMPLETE
      @on_dirs = options[ :on_dirs ] || :go_into_dirs

      # TODO think of better name
      @numbered_completion = options [ :numbered_completion ]

      @block = block
    end

    def redraw_prompt
      @diakonos.set_iline @prompt
    end

    def call_block
      if @block
        @block.call( @input )
        @window.refresh
      end
    end

    def set_input( input = '' )
      if @numbered_completion && input =~ /^\w  /
        input = input[ 3..-1 ]
      end
      @input = input
    end

    def process_keystroke( context = [], ch = nil )
      ch ||= @window.getch
      return  if ch.nil?
      c = ch.ord

      case c
      when Curses::KEY_DC
        delete
      when BACKSPACE, CTRL_H
        backspace
      when ENTER, Curses::KEY_F3
        item = @diakonos.current_list_item
        if @on_dirs == :go_into_dirs && item && File.directory?( item )
          complete_input
        else
          @done = true
        end
      when ESCAPE, CTRL_C, CTRL_D, CTRL_Q
        abort
      when Curses::KEY_LEFT
        cursor_left
      when Curses::KEY_RIGHT
        cursor_right
      when Curses::KEY_HOME
        cursor_bol
      when Curses::KEY_END
        cursor_eol
      when TAB
        complete_input
      when Curses::KEY_NPAGE
        @diakonos.page_down
        line = @diakonos.select_list_item
        if line
          set_input line
          cursor_write_input
        end
      when Curses::KEY_PPAGE
        @diakonos.page_up
        line = @diakonos.select_list_item
        if line
          set_input line
          cursor_write_input
        end
      when Curses::KEY_UP
        if @diakonos.showing_list?
          if @diakonos.list_item_selected?
            @diakonos.previous_list_item
          end
          set_input @diakonos.select_list_item
        elsif @history_index > 0
          @history[ @history_index ] = @input
          @history_index -= 1
          @input = @history[ @history_index ]
        end
        cursor_write_input
      when Curses::KEY_DOWN
        if @diakonos.showing_list?
          if @diakonos.list_item_selected?
            @diakonos.next_list_item
          end
          set_input @diakonos.select_list_item
        elsif @history_index < @history.length - 1
          @history[ @history_index ] = @input
          @history_index += 1
          @input = @history[ @history_index ]
        end
        cursor_write_input
      when CTRL_K
        @input = ""
        if @block
          @block.call @input
        end
        cursor_write_input
      when Curses::KEY_F5
        @diakonos.decrease_grep_context
        call_block
      when Curses::KEY_F6
        @diakonos.increase_grep_context
        call_block
      when CTRL_W
        @input = @input.gsub( /\W+$/, '' ).gsub( /\w+$/, '' )
        if @block
          @block.call @input
        end
        cursor_write_input
      else
        if c > 31 && c < 255 && c != BACKSPACE
          if @numbered_completion
            if(
              @diakonos.showing_list? &&
              ( (48..57).include?( c ) || (97..122).include?( c ) )
            )
              line = @diakonos.list_buffer.to_a.select { |l|
                l =~ /^#{c.chr}  /
              }[ 0 ]

              if line
                set_input line
                cursor_write_input
                @done = true
              end
            end
          else
            if @input_cursor == @input.length
              @input << c
              @window.addch c
            else
              @input = @input[ 0...@input_cursor ] + c.chr + @input[ @input_cursor..-1 ]
              @window.setpos( @window.cury, @window.curx + 1 )
              redraw_input
            end
            @input_cursor += 1
            call_block
          end
        end
      end
    end

    # Returns nil on cancel.
    def readline
      @input = @initial_text.dup
      if ! @input.empty?
        call_block
      end

      @icurx = @window.curx
      @icury = @window.cury
      @window.addstr @initial_text
      @input_cursor = @initial_text.length
      @opened_list_file = false

      if @do_complete
        complete_input
      end

      while ! @done
        process_keystroke
      end

      @diakonos.close_list_buffer

      @history[ -1 ] = @input
    end

    def redraw_input
      input = @input[ 0...Curses::cols ]

      curx = @window.curx
      cury = @window.cury
      @window.setpos( @icury, @icurx )
      @window.addstr "%-#{ Curses::cols - curx }s%s" % [ input, " " * ( Curses::cols - input.length ) ]
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
