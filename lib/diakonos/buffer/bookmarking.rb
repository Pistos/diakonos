module Diakonos

  class Buffer

    def go_to_next_bookmark
      cur_pos = Bookmark.new( self, @last_row, @last_col )
      next_bm = @bookmarks.find do |bm|
        bm > cur_pos
      end
      if next_bm
        cursor_to( next_bm.row, next_bm.col, DO_DISPLAY )
      end
    end

    def go_to_previous_bookmark
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
        cursor_to( prev.row, prev.col, DO_DISPLAY )
      end
    end

    def toggle_bookmark
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