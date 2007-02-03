class Finding
    attr_reader :start_row, :start_col, :end_row, :end_col
    attr_writer :end_row, :end_col
    
    def initialize( start_row, start_col, end_row, end_col )
        @start_row = start_row
        @start_col = start_col
        @end_row = end_row
        @end_col = end_col
    end
    
    def match( regexps, lines )
        retval = true
        
        i = @start_row + 1
        regexps[ 1..-1 ].each do |re|
            if lines[ i ] !~ re
                retval = false
                break
            end
            @end_row = i
            @end_col = Regexp.last_match[ 0 ].length
            i += 1
        end
        
        return retval
    end
end

