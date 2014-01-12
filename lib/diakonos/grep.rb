module Diakonos
  def self.grep_array( regexp, array, lines_of_context, prefix, filepath )
    num_lines = array.size
    line_numbers = []
    array.each_with_index do |line,index|
      next if line !~ regexp
      start_index = [ 0, index - lines_of_context ].max
      end_index = [ index + lines_of_context, num_lines-1 ].min
      (start_index..end_index).each do |i|
        line_numbers << i
      end
    end

    line_numbers.uniq!
    results = []
    last_i = line_numbers[ 0 ]
    one_result = []
    line_numbers.each do |i|
      if i - last_i > 1
        results << one_result.join( "\n" )
        one_result = []
      end
      one_result << ( "#{prefix}#{i+1}: " << ( "%-300s | #{filepath}:#{i+1}" % array[ i ] ) )
      last_i = i
    end
    if ! one_result.empty?
      results << one_result.join( "\n" )
    end

    results
  end

  class Diakonos

    def actually_grep( regexp_source, *buffers )
      begin
        regexp = Regexp.new( regexp_source, Regexp::IGNORECASE )
        grep_results = buffers.map { |buffer| buffer.grep(regexp) }.flatten
        if settings[ 'grep.context' ] == 0
          join_str = "\n"
        else
          join_str = "\n---\n"
        end
        with_list_file do |list|
          list.puts grep_results.join( join_str )
        end
        list_buffer = open_list_buffer
        list_buffer.highlight_matches regexp
        display_buffer list_buffer
      rescue RegexpError
        # Do nothing
      end
    end

    def grep_( regexp_source, *buffers )
      original_buffer = buffer_current
      if buffer_current.changing_selection
        selected_text = buffer_current.copy_selection[ 0 ]
      end
      starting_row, starting_col = buffer_current.last_row, buffer_current.last_col

      selected = get_user_input(
        "Grep regexp: ",
        history: @rlh_search,
        initial_text: regexp_source || selected_text || "",
        will_display_after_select: true
      ) { |input|
        next  if input.length < 2
        actually_grep input, *buffers
      }

      if selected
        spl = selected.split( "| " )
        if spl.size > 1
          open_file spl[-1]
        else
          original_buffer.cursor_to starting_row, starting_col
        end
      else
        original_buffer.cursor_to starting_row, starting_col
      end
    end

    def increase_grep_context
      current = settings['grep.context']
      @session.settings['grep.context'] = current + 1
      merge_session_settings
    end
    def decrease_grep_context
      current = settings['grep.context']
      if current > 0
        @session.settings['grep.context'] = current - 1
        merge_session_settings
      end
    end

  end
end
