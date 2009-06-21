module Diakonos

  class Buffer

    def tab_expanded_column( col, row )
      delta = 0
      line = @lines[ row ]
      for i in 0...col
        if line[ i ] == "\t"
          delta += ( @tab_size - ( (i+delta) % @tab_size ) ) - 1
        end
      end
      col + delta
    end

    def set_indent( row, level, do_display = DO_DISPLAY )
      @lines[ row ] =~ /^([\s#{@indent_ignore_charset}]*)(.*)$/
      current_indent_text = ( $1 or "" )
      rest = ( $2 or "" )
      current_indent_text.gsub!( /\t/, ' ' * @tab_size )
      indentation = @indent_size * [ level, 0 ].max
      if current_indent_text.length >= indentation
        indent_text = current_indent_text[ 0...indentation ]
      else
        indent_text = current_indent_text + " " * ( indentation - current_indent_text.length )
      end
      if @settings[ "lang.#{@language}.indent.using_tabs" ]
        num_tabs = 0
        indent_text.gsub!( / {#{@tab_size}}/ ) { |match|
          num_tabs += 1
          "\t"
        }
        indentation -= num_tabs * ( @tab_size - 1 )
      end

      take_snapshot( TYPING ) if do_display
      @lines[ row ] = indent_text + rest
      cursor_to( row, indentation ) if do_display
      set_modified
    end

    def indentation_level( row, use_indent_ignore = USE_INDENT_IGNORE )
      line = @lines[ row ]

      if use_indent_ignore
        if line =~ /^[\s#{@indent_ignore_charset}]*$/ or line == ""
          level = 0
        elsif line =~ /^([\s#{@indent_ignore_charset}]+)[^\s#{@indent_ignore_charset}]/
          whitespace = $1.expand_tabs( @tab_size )
          level = whitespace.length / @indent_size
          if @indent_roundup && ( whitespace.length % @indent_size > 0 )
            level += 1
          end
        else
          level = 0
        end
      else
        level = 0
        if line =~ /^([\s]+)/
          whitespace = $1.expand_tabs( @tab_size )
          level = whitespace.length / @indent_size
          if @indent_roundup && ( whitespace.length % @indent_size > 0 )
            level += 1
          end
        end
      end

      level
    end

    def parsed_indent( row = @last_row, do_display = DO_DISPLAY )
      if row == 0 || @lines[ row ] =~ @settings[ "lang.#{@language}.indent.not_indented" ]
        level = 0
      else
        # Look upwards for the nearest line on which to base this line's indentation.
        i = 1
        while (
          @lines[ row - i ] =~ /^[\s#{@indent_ignore_charset}]*$/ ||
          @lines[ row - i ] =~ @settings[ "lang.#{@language}.indent.ignore" ] ||
          @lines[ row - i ] =~ @settings[ "lang.#{@language}.indent.not_indented" ]
        )
          i += 1
        end

        if row - i < 0
          level = 0
        else
          prev_line = @lines[ row - i ]
          second_prev_line = ''
          if ! ( ( row - i - i ) < 0 )
            second_prev_line = @lines[ row - i - 1 ]
          end
          level = indentation_level( row - i )

          line = @lines[ row ]
          if @preventers
            prev_line = prev_line.gsub( @preventers, "" )
            line = line.gsub( @preventers, "" )
          end

          indenter_index = ( prev_line =~ @indenters )

          if prev_line =~ @indenters_next_line
            level += 1
          elsif indenter_index
            level += 1
            unindenter_index = (prev_line =~ @unindenters)
            if unindenter_index and unindenter_index != indenter_index
              level += -1
            end
          end
          if line =~ @unindenters || second_prev_line =~ @indenters_next_line
            level += -1
          end
        end
      end

      set_indent( row, level, do_display )
    end

    def indent( row = @last_row, do_display = DO_DISPLAY )
      level = indentation_level( row, DONT_USE_INDENT_IGNORE )
      set_indent( row, level + 1, do_display )
    end

    def unindent( row = @last_row, do_display = DO_DISPLAY )
      level = indentation_level( row, DONT_USE_INDENT_IGNORE )
      set_indent( row, level - 1, do_display )
    end

  end

end
