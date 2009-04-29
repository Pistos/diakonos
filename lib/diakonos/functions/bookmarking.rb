module Diakonos
  module Functions

    def add_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        @bookmarks[ name ] = Bookmark.new( @current_buffer, @current_buffer.current_row, @current_buffer.current_column, name )
        set_iline "Added bookmark #{@bookmarks[ name ].to_s}."
      end
    end

    def go_to_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        bookmark = @bookmarks[ name ]
        if bookmark
          switch_to( bookmark.buffer )
          bookmark.buffer.cursor_to( bookmark.row, bookmark.col, Buffer::DO_DISPLAY )
        else
          set_iline "No bookmark named '#{name}'."
        end
      end
    end

    def go_to_next_bookmark
      @current_buffer.go_to_next_bookmark
    end

    def go_to_previous_bookmark
      @current_buffer.go_to_previous_bookmark
    end

  end
end