module Diakonos

  class Diakonos
    attr_reader :list_buffer

    def open_list_buffer
      @list_buffer = open_file( @list_filename )
    end

    def close_list_buffer
      close_file @list_buffer
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
        @list_buffer.set_selection_current_line
      end
    end

    def select_list_item
      if @list_buffer
        line = @list_buffer.set_selection_current_line
        @list_buffer.display
        line
      end
    end

    def previous_list_item
      if @list_buffer
        cursor_up
        @list_buffer[ @list_buffer.current_row ]
      end
    end

    def next_list_item
      if @list_buffer
        cursor_down
        @list_buffer[ @list_buffer.current_row ]
      end
    end

    def with_list_file
      File.open( @list_filename, "w" ) do |f|
        yield f
      end
    end

  end

end
