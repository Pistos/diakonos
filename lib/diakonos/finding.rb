module Diakonos

  class Finding
    include RangeDelegator

    def self.confirm(range_, regexps, lines, search_area, regexp_match)
      matches = true
      range = range_.dup

      i = range.start_row + 1
      regexps[1..-1].each do |re|
        if lines[i] !~ re
          matches = false
          break
        end
        range.end_row = i
        range.end_col = Regexp.last_match[0].length
        i += 1
      end

      if (
        matches &&
        search_area.contains?( range.start_row, range.start_col ) &&
        search_area.contains?( range.end_row, range.end_col - 1 )
      )
        Finding.new(range, regexp_match)
      end
    end

    def initialize(range, regexp_match)
      @range = range
      @regexp_match = regexp_match
    end

    def captured_group(index)
      @regexp_match[index]
    end
  end

end
