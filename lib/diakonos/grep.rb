module Diakonos
  def self.grep_array( regexp, array, lines_of_context, prefix )
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
      one_result << ( "#{prefix}#{i+1}: " << ( "%-300s | #{@key}:#{i+1}" % array[ i ] ) )
      last_i = i
    end
    if not one_result.empty?
      results << one_result.join( "\n" )
    end

    results
  end

  class Diakonos

    def grep_( regexp_source, *buffers )
      original_buffer = @current_buffer
      if @current_buffer.changing_selection
        selected_text = @current_buffer.copySelection[ 0 ]
      end
      starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

      selected = getUserInput(
        "Grep regexp: ",
        @rlh_search,
        regexp_source || selected_text || ""
      ) { |input|
        next if input.length < 2
        begin
          regexp = Regexp.new( input, Regexp::IGNORECASE )
          grep_results = buffers.map { |buffer| buffer.grep( regexp ) }.flatten
          if settings[ 'grep.context' ] == 0
            join_str = "\n"
          else
            join_str = "\n---\n"
          end
          with_list_file do |list|
            list.puts grep_results.join( join_str )
          end
          list_buffer = openListBuffer
          list_buffer.highlightMatches regexp
          list_buffer.display
        rescue RegexpError
          # Do nothing
        end
      }

      if selected
        spl = selected.split( "| " )
        if spl.size > 1
          openFile spl[ -1 ]
        end
      else
        original_buffer.cursorTo starting_row, starting_col
      end
    end

  end
end