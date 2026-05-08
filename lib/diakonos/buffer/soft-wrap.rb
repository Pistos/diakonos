module Diakonos

  class Buffer

    # Visual-line helpers used by soft wrapping. All buffer (row, col)
    # coordinates remain in buffer space; these helpers translate to and
    # from "visual" space — the layout the user sees once long lines are
    # flowed across multiple terminal rows.

    # Reconciles internal state when settings (especially view.wrap.soft)
    # change between displays. Idempotent when nothing relevant has changed.
    def after_soft_wrap_toggled
      current = soft_wrap?
      if @last_soft_wrap_state != current
        if current
          @left_column = 0
        end

        new_col = tab_expanded_column( @last_col, @last_row )
        show_character( @last_row, new_col )

        position = screen_position_of( row: @last_row, expanded_col: new_col )
        @last_screen_y = position[ :y ]
        @last_screen_x = position[ :x ]
        @last_screen_col = new_col

        @last_soft_wrap_state = current
      end
    end

    def buffer_col_for_visual(row:, segment_index:, visual_x:)
      if soft_wrap?
        expanded_col = (segment_index * wrap_width) + visual_x
      else
        expanded_col = visual_x
      end

      unexpand_tab_column(row, expanded_col)
    end

    # Translate a screen position (y, x) in @win_main into a buffer (row, col).
    # Walks visual segments forward from @top_line.
    def buffer_position_at_screen(screen_x:, screen_y:)
      if soft_wrap?
        row = @top_line
        remaining_y = screen_y
        num_segments = num_visual_segments_for( row )

        while row < @lines.length - 1 && remaining_y >= num_segments
          remaining_y -= num_segments
          row += 1
          num_segments = num_visual_segments_for( row )
        end

        result = {
          col: buffer_col_for_visual(
            row:,
            segment_index: remaining_y,
            visual_x: screen_x,
          ),
          row:,
        }
      else
        result = {
          col: @left_column + screen_x,
          row: @top_line + screen_y,
        }
      end

      result
    end

    # Shift the view by +amount+ visual rows. Returns the actual number of
    # visual rows shifted. Operates in whole-buffer-row chunks: smooth
    # mid-line scrolling (via @top_segment) is a future enhancement.
    def pitch_view_visual(amount)
      if soft_wrap? && amount > 0
        pitch_down_visually( amount )
      elsif soft_wrap? && amount < 0
        pitch_up_visually( amount )
      else
        0
      end
    end

    # Translate a buffer (row, expanded_col) into a screen (y, x) in @win_main.
    def screen_position_of(row:, expanded_col:)
      if soft_wrap?
        y = (
          (@top_line...row)
          .reduce(0) { |y_, row_|
            y_ + num_visual_segments_for(row_)
          }
        ) + visual_segment_index( expanded_col )

        {
          x: visual_x_of( expanded_col ),
          y:,
        }
      else
        {
          x: expanded_col - @left_column,
          y: row - @top_line,
        }
      end
    end

    def soft_wrap?
      @settings[ 'view.wrap.soft' ]
    end

    # Number of visual rows the buffer line at +row+ occupies. Always
    # at least 1, even for empty lines.
    def num_visual_segments_for(row)
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

    private def pitch_down_visually(amount)
      new_top_line = @top_line
      accumulated = 0

      while accumulated < amount && new_top_line < @lines.length - 1
        accumulated += num_visual_segments_for( new_top_line )
        new_top_line += 1
      end

      @top_line = new_top_line

      accumulated
    end

    private def pitch_up_visually(amount)
      new_top_line = @top_line
      accumulated = 0

      while accumulated > amount && new_top_line > 0
        new_top_line -= 1
        accumulated -= num_visual_segments_for( new_top_line )
      end

      @top_line = new_top_line

      accumulated
    end

  end

end
