module Diakonos

  class Buffer

    def goToNextBookmark
      cur_pos = Bookmark.new( self, @last_row, @last_col )
      next_bm = @bookmarks.find do |bm|
        bm > cur_pos
      end
      if next_bm
        cursorTo( next_bm.row, next_bm.col, DO_DISPLAY )
      end
    end

    def goToPreviousBookmark
      cur_pos = Bookmark.new( self, @last_row, @last_col )
      # There's no reverse_find method, so, we have to do this manually.
      prev = nil
      @bookmarks.reverse_each do |bm|
        if bm < cur_pos
          prev = bm
          break
        end
      end
      if prev
        cursorTo( prev.row, prev.col, DO_DISPLAY )
      end
    end

    def toggleBookmark
      bookmark = Bookmark.new( self, @last_row, @last_col )
      existing = @bookmarks.find do |bm|
        bm == bookmark
      end
      if existing
        @bookmarks.delete existing
        @diakonos.setILine "Bookmark #{existing.to_s} deleted."
      else
        @bookmarks.push bookmark
        @bookmarks.sort
        @diakonos.setILine "Bookmark #{bookmark.to_s} set."
      end
    end

  end

end