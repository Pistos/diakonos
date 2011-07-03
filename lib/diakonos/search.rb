module Diakonos
  class Diakonos

    # @return [Fixnum] the number of replacements made
    def find_( options = {} )
      regexp_source, replacement = options.values_at( :regexp_source, :replacement )
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
            options[:case_sensitive] ? nil : Regexp::IGNORECASE
          )
          $VERBOSE = warning_verbosity
        rescue RegexpError => e
          if ! exception_thrown
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

      if exception_thrown && ! options[:quiet]
        set_iline "Searching literally; #{exception_thrown.message}"
      end

      # The execution order of the #find and the @last_search_regexps assignment is likely deliberate
      num_replacements = buffer_current.find(
        regexps,
        :direction          => options[:direction],
        :replacement        => replacement,
        :starting_row       => options[:starting_row],
        :starting_col       => options[:starting_col],
        :quiet              => options[:quiet],
        :show_context_after => @settings[ 'find.show_context_after' ],
        :starting           => true
      )
      @last_search_regexps = regexps

      num_replacements
    end

  end
end
