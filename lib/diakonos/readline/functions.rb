module Diakonos

  class Readline

    def abort
      @input = nil
      @done = true
    end

    def accept( item )
      if item && @on_dirs == :go_into_dirs && File.directory?( item )
        complete_input
      else
        @done = true
      end
    end

    def backspace
      cursor_left
      delete
    end

    def cursor_bol
      @input_cursor = 0
      @window.setpos( @icury, @icurx )
    end

    def cursor_eol
      @input_cursor = @input.length
      @window.setpos( @window.cury, @icurx + @input.length )
    end

    def cursor_left
      return  if @input_cursor < 1
      @input_cursor -= 1
      @window.setpos( @window.cury, @window.curx - 1 )
    end

    def cursor_right
      return  if @input_cursor >= @input.length
      @input_cursor += 1
      @window.setpos( @window.cury, @window.curx + 1 )
    end

    def delete
      return  if @input_cursor >= @input.length
      @window.delch
      set_input( @input[ 0...@input_cursor ] + @input[ (@input_cursor + 1)..-1 ] )
      call_block
    end

    def delete_line
      @input = ""
      if @block
        @block.call @input
      end
      cursor_write_input
    end

    def delete_word
      @input = @input.gsub( /\W+$/, '' ).gsub( /\w+$/, '' )
      sync
    end

    def history_up
      return  if @history_index < 1
      @history[ @history_index ] = @input
      @history_index -= 1
      @input = @history[ @history_index ]
    end

    def history_down
      return  if @history_index > @history.length - 2
      @history[ @history_index ] = @input
      @history_index += 1
      @input = @history[ @history_index ]
    end

  end

end