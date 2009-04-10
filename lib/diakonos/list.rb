module Diakonos

  class Diakonos

    def open_list_buffer
      @list_buffer = openFile( @list_filename )
    end

    def close_list_buffer
      closeFile( @list_buffer )
      @list_buffer = nil
    end

    def showing_list?
      @list_buffer
    end

    def list_item_selected?
      @list_buffer and @list_buffer.selecting?
    end

    def current_list_item
      if @list_buffer
        @list_buffer.select_current_line
      end
    end

    def select_list_item
      if @list_buffer
        line = @list_buffer.select_current_line
        @list_buffer.display
        line
      end
    end

    def previous_list_item
      if @list_buffer
        cursorUp
        @list_buffer[ @list_buffer.currentRow ]
      end
    end

    def next_list_item
      if @list_buffer
        cursorDown
        @list_buffer[ @list_buffer.currentRow ]
      end
    end

    def with_list_file
      File.open( @list_filename, "w" ) do |f|
        yield f
      end
    end

  end

end