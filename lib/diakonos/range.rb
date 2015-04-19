module Diakonos
  class Range
    attr_reader :start_row, :start_col, :end_row, :end_col
    attr_writer :end_row, :end_col

    def initialize( start_row, start_col, end_row, end_col )
      @start_row, @start_col, @end_row, @end_col = start_row, start_col, end_row, end_col
    end

    def contains?(row, col)
      if row == @start_row
        @start_col <= col
      elsif row == @end_row
        col < @end_col
      else
        @start_row < row && row < @end_row
      end
    end
  end

  module RangeDelegator
    def start_row; @range.start_row; end
    def end_row; @range.end_row; end
    def start_col; @range.start_col; end
    def end_col; @range.end_col; end

    def contains?(row, col)
      @range.contains?(row, col)
    end
  end
end
