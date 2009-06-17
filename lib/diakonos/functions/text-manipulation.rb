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

    def complete_word
      b = @current_buffer
      if b.selecting?
        old_word = @current_buffer.word_before_cursor
        b.delete_selection
      end
      partial = @current_buffer.word_before_cursor
      return  if partial.nil?

      words = @buffers.values.collect { |b| b.words }.flatten
      words = words.grep( /^#{Regexp.escape(partial)}./ ).sort
      if words.any?
        if old_word
          i = words.find_index { |w| w == old_word } + 1
          if i == words.size
            i = 0
          end
        else
          i = 0
        end
        word = words[ i ]
        b.insert_string word[ partial.length..-1 ]
        b.set_selection( b.last_row, b.last_col, b.last_row, b.last_col + word.length - partial.length )
        set_iline word.center( Curses::cols )
      end
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