class String
    def to_b
      case downcase
      when "true", "t", "1", "yes", "y", "on", "+"
        true
      else
        false
      end
    end

    def expandTabs( tab_size = Diakonos::DEFAULT_TAB_SIZE )
      s = dup
      while s.sub!( /\t/ ) { |match_text|
        match = Regexp.last_match
        index = match.begin( 0 )
        # Return value for block:
        " " * ( tab_size - ( index % tab_size ) )
      }
      end
      s
    end

    def newlineSplit
      retval = split( /\\n/ )
      if self =~ /\\n$/
        retval << ""
      end
      if retval.length > 1
        retval[ 0 ] << "$"
        retval[ 1..-2 ].collect do |el|
          "^" << el << "$"
        end
        retval[ -1 ] = "^" << retval[ -1 ]
      end
      retval
    end

    # Works like normal String#index except returns the index
    # of the first matching regexp group if one or more groups are specified
    # in the regexp. Both the index and the matched text are returned.
    def group_index( regexp, offset = 0 )
      if regexp.class != Regexp
        return index( regexp, offset )
      end

      i = nil
      match_text = nil
      working_offset = 0
      loop do
        index( regexp, working_offset )
        match = Regexp.last_match
        if match
          i = match.begin( 0 )
          match_text = match[ 0 ]
          if match.length > 1
            # Find first matching group
            1.upto( match.length - 1 ) do |match_item_index|
              if match[ match_item_index ]
                i = match.begin( match_item_index )
                match_text = match[ match_item_index ]
                break
              end
            end
          end

          break if i >= offset
        else
          i = nil
          break
        end
        working_offset += 1
      end

      [ i, match_text ]
    end

    # Works like normal String#rindex except returns the index
    # of the first matching regexp group if one or more groups are specified
    # in the regexp. Both the index and the matched text are returned.
    def group_rindex( regexp, offset = length )
      if regexp.class != Regexp
        return rindex( regexp, offset )
      end

      i = nil
      match_text = nil
      working_offset = length
      loop do
        rindex( regexp, working_offset )
        match = Regexp.last_match
        if match
          i = match.end( 0 ) - 1
          match_text = match[ 0 ]
          if match.length > 1
            # Find first matching group
            1.upto( match.length - 1 ) do |match_item_index|
              if match[ match_item_index ]
                i = match.end( match_item_index ) - 1
                match_text = match[ match_item_index ]
                break
              end
            end
          end

          if match_text == ""
            # Assume that an empty string means that it matched $
            i += 1
          end

          break if i <= offset
        else
          i = nil
          break
        end
        working_offset -= 1
      end

      [ i, match_text ]
    end

    def movement?
      self =~ /^((cursor|page|scroll)(Up|Down|Left|Right)|find)/
    end

    # Backport of Ruby 1.9's String#ord into Ruby 1.8
    if ! method_defined?( :ord )
      def ord
        self[ 0 ]
      end
    end
end

