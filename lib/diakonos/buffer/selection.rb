module Diakonos

  class Buffer

    # @mark_start[ "col" ] is inclusive,
    # @mark_end[ "col" ] is exclusive.
    def recordMarkStartAndEnd
      if @mark_anchor.nil?
        @text_marks[ SELECTION ] = nil
        return
      end

      crow = @last_row
      ccol = @last_col
      arow = @mark_anchor[ 'row' ]
      acol = @mark_anchor[ 'col' ]

      case @selection_mode
      when :normal
        anchor_first = true

        if crow < arow
          anchor_first = false
        elsif crow > arow
          anchor_first = true
        else
          if ccol < acol
            anchor_first = false
          end
        end

        if anchor_first
          @text_marks[ SELECTION ] = TextMark.new( arow, acol, crow, ccol, @selection_formatting )
        else
          @text_marks[ SELECTION ] = TextMark.new( crow, ccol, arow, acol, @selection_formatting )
        end
      when :block
        if crow < arow
          if ccol < acol # Northwest
            @text_marks[ SELECTION ] = TextMark.new( crow, ccol, arow, acol, @selection_formatting )
          else           # Northeast
            @text_marks[ SELECTION ] = TextMark.new( crow, acol, arow, ccol, @selection_formatting )
          end
        else
          if ccol < acol  # Southwest
            @text_marks[ SELECTION ] = TextMark.new( arow, ccol, crow, acol, @selection_formatting )
          else            # Southeast
            @text_marks[ SELECTION ] = TextMark.new( arow, acol, crow, ccol, @selection_formatting )
          end
        end
      end
    end

    def selection_mark
      @text_marks[ SELECTION ]
    end
    def selecting?
      !!selection_mark
    end

    def select_current_line
      @text_marks[ SELECTION ] = TextMark.new(
        @last_row,
        0,
        @last_row,
        @lines[ @last_row ].size,
        @selection_formatting
      )
      @lines[ @last_row ]
    end

    def select_all
      selection_mode_normal
      anchorSelection( 0, 0, DONT_DISPLAY )
      cursorTo( @lines.length - 1, @lines[ -1 ].length, DO_DISPLAY )
    end

    def select( from_regexp, to_regexp, include_ending = true )
      start_row = nil

      @lines[ 0..@last_row ].reverse.each_with_index do |line,index|
        if line =~ from_regexp
          start_row = @last_row - index
          break
        end
      end
      if start_row
        end_row = nil
        @lines[ start_row..-1 ].each_with_index do |line,index|
          if line =~ to_regexp
            end_row = start_row + index
            break
          end
        end
        if end_row
          if include_ending
            end_row += 1
          end
          anchorSelection( start_row, 0, DONT_DISPLAY )
          cursorTo( end_row, 0 )
          display
        end
      end
    end

  end

end