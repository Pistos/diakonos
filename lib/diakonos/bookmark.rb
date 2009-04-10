module Diakonos

class Bookmark
    attr_reader :buffer, :row, :col, :name

    def initialize( buffer, row, col, name = nil )
        @buffer = buffer
        @row = row
        @col = col
        @name = name
    end

    def == (other)
        return false if other.nil?
        ( @buffer == other.buffer and @row == other.row and @col == other.col )
    end

    def <=> (other)
        return nil if other.nil?
        comparison = ( $diakonos.bufferToNumber( @buffer ) <=> $diakonos.bufferToNumber( other.buffer ) )
        return comparison if comparison != 0
        comparison = ( @row <=> other.row )
        return comparison if comparison != 0
        @col <=> other.col
    end

    def < (other)
        ( ( self <=> other ) < 0 )
    end
    def > (other)
        ( ( self <=> other ) > 0 )
    end

    def shift( row_inc, col_inc )
        row += row_inc
        col += col_inc
    end

    def to_s
        "[#{@name}|#{@buffer.name}:#{@row+1},#{@col+1}]"
    end
end

end