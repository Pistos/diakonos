module Diakonos
  module Functions
    def addNamedBookmark( name_ = nil )
      if name_.nil?
        name = getUserInput "Bookmark name: "
      else
        name = name_
      end
      
      if name
        @bookmarks[ name ] = Bookmark.new( @current_buffer, @current_buffer.currentRow, @current_buffer.currentColumn, name )
        setILine "Added bookmark #{@bookmarks[ name ].to_s}."
      end
    end
    
    def anchorSelection
      @current_buffer.anchorSelection
      updateStatusLine
    end
    
    def backspace
      delete if( @current_buffer.changing_selection or cursorLeft( Buffer::STILL_TYPING ) )
    end
    
    def carriageReturn
      @current_buffer.carriageReturn
      @current_buffer.deleteSelection
    end
    
  end
end