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
      if cursor_left
        delete
      end
    end

    def cursor_bol
      @input_cursor = 0
      sync
    end

    def cursor_eol
      @input_cursor = @input.length
      sync
    end

    def cursor_left
      return false  if @input_cursor < 1
      @input_cursor -= 1
      sync
      true
    end

    def cursor_right
      return  if @input_cursor >= @input.length
      @input_cursor += 1
      sync
    end

    def delete
      return  if @input_cursor >= @input.length
      @input = @input[ 0...@input_cursor ] + @input[ (@input_cursor + 1)..-1 ]
      sync
    end

    def delete_line
      @input = ""
      sync
    end

    def delete_word
      head = @input[ 0...@input_cursor ]
      chopped = head.sub( /\w+\W*$/, '' )
      @input = chopped + @input[ @input_cursor..-1 ]
      @input_cursor -= head.length - chopped.length
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