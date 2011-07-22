module Diakonos
  module Functions

    def close_code
      buffer_current.close_code
    end

    def collapse_whitespace
      buffer_current.collapse_whitespace
    end


    def columnize( delimiter = nil, num_spaces_padding = 0 )
      delimiter ||= get_user_input(
        "Column delimiter (regexp): ",
        history: @rlh_general,
        initial_text: @settings[ "lang.#{buffer_current.original_language}.column_delimiters" ] || ''
      )
      if delimiter && num_spaces_padding
        buffer_current.columnize Regexp.new( delimiter ), num_spaces_padding
      end
    end

    def comment_out
      buffer_current.comment_out
    end

    def complete_word( direction = :down )
      b = buffer_current
      if b.selecting?
        old_word = b.word_before_cursor
        b.delete_selection
      end
      partial = b.word_before_cursor
      return  if partial.nil?

      all_words = @buffers.find_all { |b_|
        b_.original_language == b.original_language
      }.collect { |b_|
        b_.words( /^#{Regexp.escape(partial)}./ )
      }.flatten
      if all_words.any?
        words = all_words.uniq.sort
        if old_word
          i = (
            ( direction == :up ? words.size - 1 : 1 ) +
            words.find_index { |w|
              w == old_word
            }
          ) % words.size
        else
          freq_word = words.sort_by { |word|
            all_words.find_all { |w| w == word }.size
          }[ -1 ]
          i = words.find_index { |w| w == freq_word }
        end
        word = words[ i ]
        b.insert_string word[ partial.length..-1 ]
        r, c = b.last_row, b.last_col
        b.cursor_to( b.last_row, b.last_col + word.length - partial.length )
        b.set_selection( r, c, r, c + word.length - partial.length )
        n = words.size
        middle_word = words[ i ].center( Curses::cols / 4, ' ' )
        shown_words = [
          words[ ( n+i-2 ) % n ],
          words[ ( n+i-1 ) % n ],
          middle_word,
          words[ ( n+i+1 ) % n ],
          words[ ( n+i+2 ) % n ],
        ].compact.uniq.reject { |w| w == middle_word.strip }.join( ' ' )
        mi = shown_words.index( middle_word )
        padding = " " * ( Curses::cols / 2 - mi - ( middle_word.length / 2 ) )
        set_iline padding + shown_words
      end
    end

    def join_lines_upward
      buffer_current.join_lines_upward( buffer_current.current_row, Buffer::STRIP_LINE )
    end

    def join_lines
      buffer_current.join_lines( buffer_current.current_row, Buffer::STRIP_LINE )
    end

    def operate_on_string(
      ruby_code = get_user_input(
        'Ruby code: ',
        history: @rlh_general,
        initial_text: 'str.'
      )
    )
      if ruby_code
        str = buffer_current.selected_string
        if str and not str.empty?
          buffer_current.paste eval( ruby_code )
        end
      end
    end

    def operate_on_lines(
      ruby_code = get_user_input(
        'Ruby code: ',
        history: @rlh_general,
        initial_text: 'lines.collect { |l| l }'
      )
    )
      if ruby_code
        lines = buffer_current.selected_text
        if lines and not lines.empty?
          if lines[ -1 ].empty?
            lines.pop
            popped = true
          end
          new_lines = eval( ruby_code )
          if popped
            new_lines << ''
          end
          buffer_current.paste new_lines
        end
      end
    end

    def operate_on_each_line(
      ruby_code = get_user_input(
        'Ruby code: ',
        history: @rlh_general,
        initial_text: 'line.'
      )
    )
      if ruby_code
        lines = buffer_current.selected_text
        if lines and not lines.empty?
          if lines[ -1 ].empty?
            lines.pop
            popped = true
          end
          new_lines = eval( "lines.collect { |line| #{ruby_code} }" )
          if popped
            new_lines << ''
          end
          buffer_current.paste new_lines
        end
      end
    end

    def surround_line( envelope = nil )
      buffer_current.set_selection_current_line
      surround_selection envelope
    end

    def surround_paragraph( envelope = nil )
      ( first, _ ), ( last, length ) = buffer_current.paragraph_under_cursor_pos
      buffer_current.set_selection( first, 0, last, length+1 )
      surround_selection envelope
    end

    def surround_selection( parenthesis = nil )
      if ! buffer_current.selecting?
        set_iline "Nothing selected."
        return
      end

      parenthesis ||= get_user_input( "Surround with: " )
      if parenthesis
        text = buffer_current.surround( buffer_current.selected_text, parenthesis )
        if text
          buffer_current.paste text
        end
      end
    end

    def surround_word( envelope = nil )
      ( start_row, start_col ), ( end_row, end_col ) = buffer_current.word_under_cursor_pos
      if start_row && start_col && end_row && end_col
        buffer_current.set_selection( start_row, start_col, end_row, end_col )
        surround_selection envelope
      end
    end

    def uncomment
      buffer_current.uncomment
    end

    def wrap_paragraph
      buffer_current.wrap_paragraph
    end

  end
end
