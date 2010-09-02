module Diakonos
  module Functions

    def add_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        @bookmarks[ name ] = Bookmark.new( buffer_current, buffer_current.current_row, buffer_current.current_column, name )
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
      buffer_current.go_to_next_bookmark
    end

    def go_to_previous_bookmark
      buffer_current.go_to_previous_bookmark
    end

    def remove_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        bookmark = @bookmarks.delete name
        set_iline "Removed bookmark #{bookmark.to_s}."
      end
    end

    def toggle_bookmark
      buffer_current.toggle_bookmark
    end

  end
end