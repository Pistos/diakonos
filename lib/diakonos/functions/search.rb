module Diakonos
  module Functions

    # Worker method for find function.
    def find_( direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, quiet )
      return  if regexp_source.nil? || regexp_source.empty?

      rs_array = regexp_source.newline_split
      regexps = Array.new
      exception_thrown = nil

      rs_array.each do |source|
        begin
          warning_verbosity = $VERBOSE
          $VERBOSE = nil
          regexps << Regexp.new(
            source,
            case_sensitive ? nil : Regexp::IGNORECASE
          )
          $VERBOSE = warning_verbosity
        rescue RegexpError => e
          if not exception_thrown
            exception_thrown = e
            source = Regexp.escape( source )
            retry
          else
            raise e
          end
        end
      end

      if replacement == ASK_REPLACEMENT
        replacement = get_user_input( "Replace with: ", history: @rlh_search )
      end

      if exception_thrown and not quiet
        set_iline( "Searching literally; #{exception_thrown.message}" )
      end

      @current_buffer.find(
        regexps,
        :direction          => direction,
        :replacement        => replacement,
        :starting_row       => starting_row,
        :starting_col       => starting_col,
        :quiet              => quiet,
        :show_context_after => @settings[ 'find.show_context_after' ]
      )
      @last_search_regexps = regexps
      @current_buffer.search_area = nil
    end

    def find( dir_str = "down", case_sensitive = CASE_INSENSITIVE, regexp_source_ = nil, replacement = nil )
      direction = direction_of( dir_str )
      if regexp_source_
        regexp_source = regexp_source_
      else
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

        regexp_source = get_user_input(
          "Search regexp: ",
          history: @rlh_search,
          initial_text: selected_text || ""
        ) { |input|
          if input.length > 1
            find_ direction, case_sensitive, input, nil, starting_row, starting_col, QUIET
          else
            @current_buffer.remove_selection Buffer::DONT_DISPLAY
            @current_buffer.clear_matches Buffer::DO_DISPLAY
          end
        }
      end

      if regexp_source
        find_ direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, NOISY
      elsif starting_row && starting_col
        @current_buffer.clear_matches
        if @settings[ 'find.return_on_abort' ]
          @current_buffer.cursor_to starting_row, starting_col, Buffer::DO_DISPLAY
        end
      end
    end

    def find_again( dir_str = nil )
      if dir_str
        direction = direction_of( dir_str )
        @current_buffer.find_again( @last_search_regexps, direction )
      else
        @current_buffer.find_again( @last_search_regexps )
      end
    end

    def find_in_selection( *args )
      if ! @current_buffer.selecting?
        set_iline "First mark a selection to search within."
        return
      end
      @current_buffer.search_area = @current_buffer.selection_mark
      @current_buffer.remove_selection
      find *args
    end

    def find_exact( dir_str = "down", search_term_ = nil )
      if search_term_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        search_term = get_user_input(
          "Search for: ",
          history: @rlh_search,
          initial_text: selected_text || ""
        )
      else
        search_term = search_term_
      end
      if search_term
        direction = direction_of( dir_str )
        regexp = [ Regexp.new( Regexp.escape( search_term ) ) ]
        @current_buffer.find( regexp, :direction => direction )
        @last_search_regexps = regexp
        @current_buffer.search_area = nil
      end
    end

    def go_to_pair_match
      @current_buffer.go_to_pair_match
    end

    def search_and_replace( case_sensitive = CASE_INSENSITIVE )
      find( "down", case_sensitive, nil, ASK_REPLACEMENT )
    end
    alias_method :find_and_replace, :search_and_replace

    def seek( regexp_source, dir_str = "down" )
      if regexp_source
        direction = direction_of( dir_str )
        regexp = Regexp.new( regexp_source )
        @current_buffer.seek( regexp, direction )
      end
    end

  end
end