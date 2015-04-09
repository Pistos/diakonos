module Diakonos

  class Finding
    attr_reader :start_row, :start_col, :end_row, :end_col
    attr_writer :end_row, :end_col

    def initialize( start_row, start_col, end_row, end_col )
      @start_row = start_row
      @start_col = start_col
      @end_row = end_row
      @end_col = end_col
    end

    def match( regexps, lines, search_area )
      matches = true

      i = @start_row + 1
      regexps[ 1..-1 ].each do |re|
        if lines[ i ] !~ re
          matches = false
          break
        end
        @end_row = i
        @end_col = Regexp.last_match[ 0 ].length
        i += 1
      end

      matches &&
      search_area.contains?( self.start_row, self.start_col ) &&
      search_area.contains?( self.end_row, self.end_col - 1 )
    end
  end

end
