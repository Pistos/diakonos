module Diakonos
  class LineMover
    def initialize(buffer:)
      @buffer = buffer
    end

    def move_selected_lines(direction:)
      case direction
      when :up
        from_row = start_row-1
        return  if from_row < 0
        to_row = end_row-1
        selection_delta = 0
      when :down
        from_row = end_row
        to_row = start_row
        return  if to_row > @buffer.lines.count - 2
        selection_delta = @buffer.selecting? ? 1 : 0
      end

      @buffer.take_snapshot Buffer::TYPING
      @buffer.lines.insert(
        to_row,
        @buffer.lines.delete_at(from_row)
      )
      if @buffer.selecting?
        @buffer.set_selection to_row+selection_delta, 0, from_row+1+selection_delta, 0
        @buffer.anchor_selection to_row+selection_delta
      end
      @buffer.go_to_line from_row+selection_delta
      @buffer.set_modified
    end

    private def start_row
      @buffer.selection_mark&.start_row || @buffer.current_row
    end

    private def end_row
      @buffer.selection_mark&.end_row || @buffer.last_row+1
    end
  end
end
