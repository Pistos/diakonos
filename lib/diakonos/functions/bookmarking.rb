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

  end
end