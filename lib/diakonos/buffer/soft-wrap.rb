module Diakonos

  class Buffer

    # Visual-line helpers used by soft wrapping. All buffer (row, col)
    # coordinates remain in buffer space; these helpers translate to and
    # from "visual" space — the layout the user sees once long lines are
    # flowed across multiple terminal rows.

    def buffer_col_for_visual(row:, segment_index:, visual_x:)
      if soft_wrap?
        expanded_col = (segment_index * wrap_width) + visual_x
      else
        expanded_col = visual_x
      end

      unexpand_tab_column(row, expanded_col)
    end

    def soft_wrap?
      @settings[ 'view.wrap.soft' ]
    end

    # Number of visual rows the buffer line at +row+ occupies. Always
    # at least 1, even for empty lines.
    def visual_segments_for(row)
      if soft_wrap?
        expanded_length = (
          @lines[row]
          .expand_tabs(@tab_size)
          .length
        )

        if expanded_length == 0
          1
        else
          (
            (expanded_length - 1) / wrap_width
          ) + 1
        end
      else
        1
      end
    end

    def visual_segment_index(expanded_col)
      if soft_wrap?
        expanded_col / wrap_width
      else
        0
      end
    end

    def visual_x_of(expanded_col)
      if soft_wrap?
        expanded_col % wrap_width
      else
        expanded_col
      end
    end

    # Visible columns available for buffer text on a single visual row.
    # Accounts for the line-numbers gutter when present.
    def wrap_width
      if @win_line_numbers
        gutter = @settings['view.line_numbers.width'] + COLUMNS_FOR_DIAGNOSTICS
      else
        gutter = 0
      end

      Curses.cols - gutter
    end

  end

end
