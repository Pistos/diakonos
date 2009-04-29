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

    def operate_on_string(
        ruby_code = get_user_input( 'Ruby code: ', @rlh_general, 'str.' )
    )
      if ruby_code
        str = @current_buffer.selected_string
        if str and not str.empty?
          @current_buffer.paste eval( ruby_code )
        end
      end
    end

    def operate_on_lines(
        ruby_code = get_user_input( 'Ruby code: ', @rlh_general, 'lines.collect { |l| l }' )
    )
      if ruby_code
        lines = @current_buffer.selected_text
        if lines and not lines.empty?
          if lines[ -1 ].empty?
            lines.pop
            popped = true
          end
          new_lines = eval( ruby_code )
          if popped
            new_lines << ''
          end
          @current_buffer.paste new_lines
        end
      end
    end

    def operate_on_each_line(
        ruby_code = get_user_input( 'Ruby code: ', @rlh_general, 'line.' )
    )
      if ruby_code
        lines = @current_buffer.selected_text
        if lines and not lines.empty?
          if lines[ -1 ].empty?
            lines.pop
            popped = true
          end
          new_lines = eval( "lines.collect { |line| #{ruby_code} }" )
          if popped
            new_lines << ''
          end
          @current_buffer.paste new_lines
        end
      end
    end

    def uncomment
      @current_buffer.uncomment
    end

    def wrap_paragraph
      @current_buffer.wrap_paragraph
    end

  end
end