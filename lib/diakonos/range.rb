module Diakonos
  class Range
    attr_reader :start_row, :start_col, :end_row, :end_col
    attr_writer :end_row, :end_col

    def initialize( start_row, start_col, end_row, end_col )
      @start_row, @start_col, @end_row, @end_col = start_row, start_col, end_row, end_col
    end
  end
end
