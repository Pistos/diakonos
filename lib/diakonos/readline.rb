module Diakonos
  
  class Readline
    
    # completion_array is the array of strings that tab completion can use
    # The block returns true if a refresh is needed?
    def initialize( diakonos, window, prompt, initial_text = "", completion_array = nil, history = [], &block )
      @diakonos = diakonos
      @window = window
      @prompt = prompt
      pos = redraw_prompt
      @window.setpos( 0, pos )
      @initial_text = initial_text
      @completion_array = completion_array
      @list_filename = @diakonos.list_filename
      
      @history = history
      @history << initial_text
      @history_index = @history.length - 1
      
      @block = block
    end
    
    def redraw_prompt
      @diakonos.setILine @prompt
    end
    
    def call_block
      if @block
        @block.call( @input )
        @window.refresh
      end
    end
    
    # Returns nil on cancel.
    def readline
      @input = @initial_text
      @icurx = @window.curx
      @icury = @window.cury
      @window.addstr @initial_text
      @input_cursor = @initial_text.length
      @opened_list_file = false
      
      loop do
        c = @window.getch
        
        case c
        when Curses::KEY_DC
          if @input_cursor < @input.length
            @window.delch
            @input = @input[ 0...@input_cursor ] + @input[ (@input_cursor + 1)..-1 ]
            call_block
          end
        when BACKSPACE, CTRL_H
          # Curses::KEY_LEFT
          if @input_cursor > 0
            @input_cursor += -1
            @window.setpos( @window.cury, @window.curx - 1 )
            
            # Curses::KEY_DC
            if @input_cursor < @input.length
              @window.delch
              @input = @input[ 0...@input_cursor ] + @input[ (@input_cursor + 1)..-1 ]
              call_block
            end
          end
        when ENTER, Curses::KEY_F3
          item = @diakonos.current_list_item
          if item and File.directory? item
            completeInput
          else
            break
          end
        when ESCAPE, CTRL_C, CTRL_D, CTRL_Q
          @input = nil
          break
        when Curses::KEY_LEFT
          if @input_cursor > 0
            @input_cursor += -1
            @window.setpos( @window.cury, @window.curx - 1 )
          end
        when Curses::KEY_RIGHT
          if @input_cursor < @input.length
            @input_cursor += 1
            @window.setpos( @window.cury, @window.curx + 1 )
          end
        when Curses::KEY_HOME
          @input_cursor = 0
          @window.setpos( @icury, @icurx )
        when Curses::KEY_END
          @input_cursor = @input.length
          @window.setpos( @window.cury, @icurx + @input.length )
        when TAB
          completeInput
        when Curses::KEY_NPAGE
          @diakonos.pageDown
          line = @diakonos.select_list_item
          if line
            @input = line
            cursorWriteInput
          end
        when Curses::KEY_PPAGE
          @diakonos.pageUp
          line = @diakonos.select_list_item
          if line
            @input = line
            cursorWriteInput
          end
        when Curses::KEY_UP
          if @diakonos.showing_list?
            if @diakonos.list_item_selected?
              @diakonos.previous_list_item
            end
            @input = @diakonos.select_list_item
          elsif @history_index > 0
            @history[ @history_index ] = @input
            @history_index -= 1
            @input = @history[ @history_index ]
          end
          cursorWriteInput
        when Curses::KEY_DOWN
          if @diakonos.showing_list?
            if @diakonos.list_item_selected?
              @diakonos.next_list_item
            end
            @input = @diakonos.select_list_item
          elsif @history_index < @history.length - 1
            @history[ @history_index ] = @input
            @history_index += 1
            @input = @history[ @history_index ]
          end
          cursorWriteInput
        when CTRL_K
          @input = ""
          if @block
            @block.call @input
          end
          cursorWriteInput
        else
          if c > 31 and c < 255 and c != BACKSPACE
            if @input_cursor == @input.length
              @input << c
              @window.addch c
            else
              @input = @input[ 0...@input_cursor ] + c.chr + @input[ @input_cursor..-1 ]
              @window.setpos( @window.cury, @window.curx + 1 )
              redrawInput
            end
            @input_cursor += 1
            call_block
          else
            @diakonos.log "Other input: #{c}"
          end
        end
      end
      
      @diakonos.closeListBuffer
      
      @history[ -1 ] = @input
    end

    def redrawInput
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
    def cursorWriteInput
      if @input != nil
        @input_cursor = @input.length
        @window.setpos( @window.cury, @icurx + @input.length )
        redrawInput
      end
    end

    def completeInput
      if @completion_array != nil and @input.length > 0
        len = @input.length
        matches = @completion_array.find_all { |el| el[ 0...len ] == @input and len < el.length }
      else
        matches = Dir.glob( ( @input.subHome() + "*" ).gsub( /\*\*/, "*" ) )
      end
      
      if matches.length == 1
        @input = matches[ 0 ]
        cursorWriteInput
        File.open( @list_filename, "w" ) do |f|
          f.puts "(unique)"
        end
        if @completion_array == nil and FileTest.directory?( @input )
          @input << "/"
          cursorWriteInput
          completeInput
        end
      elsif matches.length > 1
        common = matches[ 0 ]
        File.open( @list_filename, "w" ) do |f|
          i = nil
          matches.each do |match|
            f.print match
            if FileTest.directory?( match )
              f.print '/'
            else
              @diakonos.log "'#{match}' is not a directory"
            end
            f.puts
            
            if match[ 0 ] != common[ 0 ]
              common = nil
              break
            end
            
            up_to = [ common.length - 1, match.length - 1 ].min
            i = 1
            while ( i <= up_to ) and ( match[ 0..i ] == common[ 0..i ] )
              i += 1
            end
            common = common[ 0...i ]
          end
        end
        if common == nil
          File.open( @list_filename, "w" ) do |f|
            f.puts "(no matches)"
          end
        else
          @input = common
          cursorWriteInput
        end
      else
        File.open( @list_filename, "w" ) do |f|
          f.puts "(no matches)"
        end
      end
      @diakonos.openListBuffer
      @window.setpos( @window.cury, @window.curx )
    end
    
  end

end