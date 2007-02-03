module Enumerable
    # Returns [array-index, string-index, string-index] triples for each match.
    def grep_indices( regexp )
        array = Array.new
        each_with_index do |element,index|
            element.scan( regexp ) do |match_text|
                match = Regexp.last_match
                strindex = match.begin( 0 )
                array.push [ index, strindex, strindex + match_text.length ]
            end
        end
        return array
    end
end

