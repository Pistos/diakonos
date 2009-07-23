module Diakonos

  class TextMark
    attr_reader :formatting, :start_row, :start_col, :end_row, :end_col

    def initialize( start_row, start_col, end_row, end_col, formatting )
      @start_row = start_row
      @start_col = start_col
      @end_row = end_row
      @end_col = end_col
      @formatting = formatting
    end

    def to_s
      "(#{start_row},#{start_col})-(#{end_row},#{end_col}) #{formatting}"
    end

    def contains?( row, col )
      if row == start_row
        start_col <= col
      elsif row == end_row
        col < end_col
      else
        start_row < row && row < end_row
      end
    end
  end

end