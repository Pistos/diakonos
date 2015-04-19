require 'diakonos/range'

module Diakonos

  class TextMark
    attr_reader :formatting
    include RangeDelegator

    def initialize( range, formatting )
      @range = range
      @formatting = formatting
    end

    def to_s
      "(#{@range.start_row},#{@range.start_col})-(#{@range.end_row},#{@range.end_col}) #{formatting}"
    end
  end

end
