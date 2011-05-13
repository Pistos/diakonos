module Diakonos
  class Diakonos

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

      buffer_current.find(
        regexps,
        :direction          => direction,
        :replacement        => replacement,
        :starting_row       => starting_row,
        :starting_col       => starting_col,
        :quiet              => quiet,
        :show_context_after => @settings[ 'find.show_context_after' ]
      )
      @last_search_regexps = regexps
    end

  end
end
