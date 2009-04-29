module Diakonos
  module Functions

    def close_code
      @current_buffer.close_code
    end

    def collapse_whitespace
      @current_buffer.collapse_whitespace
    end

    def columnize( delimiter = nil, num_spaces_padding = 0 )
      if delimiter.nil?
        delimiter = get_user_input(
          "Column delimiter (regexp): ",
          @rlh_general,
          @settings[ "lang.#{@current_buffer.original_language}.column_delimiters" ] || ''
        )
      end
      if delimiter && num_spaces_padding
        @current_buffer.columnize Regexp.new( delimiter ), num_spaces_padding
      end
    end

    def comment_out
      @current_buffer.comment_out
    end

    def join_lines
      @current_buffer.join_lines( @current_buffer.current_row, Buffer::STRIP_LINE )
    end

  end
end