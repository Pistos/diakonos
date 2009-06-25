module Diakonos

  class Readline

    def delete
      return  if @input_cursor >= @input.length
      @window.delch
      set_input( @input[ 0...@input_cursor ] + @input[ (@input_cursor + 1)..-1 ] )
      call_block
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

    def backspace
      cursor_left
      delete
    end

  end

end