module Diakonos
  module Functions

    # Searches for matches of a regular expression in the current buffer.
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    # @param [Boolean] case_sensitive
    #   Whether or not the search should be case_sensitive.  Default is insensitive.
    # @param [String] regexp_source_
    #   The regular expression to search for.
    # @param [String] replacement
    #   If provided, do a find and replace, and replace matches with replacement.
    # @see #find_exact
    # @see #find_again
    def find( dir_str = "down", case_sensitive = CASE_INSENSITIVE, regexp_source_ = nil, replacement = nil )
      direction = direction_of( dir_str )
      if regexp_source_
        regexp_source = regexp_source_
      else
        @current_buffer.search_area = nil
        m = @current_buffer.selection_mark
        if m
          if m.start_row != m.end_row
            @current_buffer.search_area = @current_buffer.selection_mark
            @current_buffer.remove_selection
          else
            selected_text = @current_buffer.copy_selection[ 0 ]
          end
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

    # Search again for the most recently sought search term.
    # @param [String] dir_str
    #   The direction to search; 'up' or 'down'.
    # @see #find
    # @see #find_exact
    def find_again( dir_str = nil )
      if dir_str
        direction = direction_of( dir_str )
        @current_buffer.find_again( @last_search_regexps, direction )
      else
        @current_buffer.find_again( @last_search_regexps )
      end
    end

    # Search for an exact string (not a regular expression).
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    # @param [String] search_term_
    #   The thing to search for.
    # @see #find
    # @see #find_again
    def find_exact( dir_str = "down", search_term_ = nil )
      @current_buffer.search_area = nil
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
      end
    end

    # Moves the cursor to the pair match of the current character, if any.
    def go_to_pair_match
      @current_buffer.go_to_pair_match
    end

    # Wrapper method for calling #find for search and replace.
    # @see #find
    def search_and_replace( case_sensitive = CASE_INSENSITIVE )
      find( "down", case_sensitive, nil, ASK_REPLACEMENT )
    end
    alias_method :find_and_replace, :search_and_replace

    # Immediately moves the cursor to the next match of a regular expression.
    # The user is not prompted for any value.
    # @param [String] regexp_source
    #   The regular expression to search for.
    # @param [String] dir_str
    #   The direction to search; 'down' (default) or 'up'.
    def seek( regexp_source, dir_str = "down" )
      if regexp_source
        direction = direction_of( dir_str )
        regexp = Regexp.new( regexp_source )
        @current_buffer.seek( regexp, direction )
      end
    end

  end
end