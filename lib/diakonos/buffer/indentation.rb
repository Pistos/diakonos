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

    def set_indent( row, level, opts = {} )
      do_display = opts.fetch( :do_display, true )
      undoable   = opts.fetch( :undoable,   true )
      cursor_eol = opts.fetch( :cursor_eol, false )

      @lines[ row ] =~ /^([\s#{@indent_ignore_charset}]*)(.*)$/
      current_indent_text = ( $1 || "" )
      rest = ( $2 || "" )
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

      take_snapshot( TYPING )  if do_display && undoable
      @lines[ row ] = indent_text + rest
      if do_display
        cursor_to(
          row,
          cursor_eol ? @lines[row].length : indentation
        )
      end
      set_modified do_display
    end

    def indentation_level( row, use_indent_ignore = USE_INDENT_IGNORE )
      line = @lines[ row ]

      if use_indent_ignore
        if line =~ /^[\s#{@indent_ignore_charset}]*$/ || line == ""
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

    # @param starting_row [Integer]
    # @param next_line_check [Boolean]
    # @return [Integer]
    def nearest_basis_row_from(starting_row, next_line_check = true)
      row = starting_row-1

      if @lines[row] =~ @indenters_next_line || @lines[row] =~ @indenters
        return row
      end

      loop do
        return nil  if row.nil? || row < 0

        while (
          @lines[row] =~ /^[\s#{@indent_ignore_charset}]*$/ ||
          @lines[row] =~ @settings[ "lang.#{@language}.indent.ignore" ] ||
          @lines[row] =~ @settings[ "lang.#{@language}.indent.not_indented" ]
        )
          row = nearest_basis_row_from(row)
          return nil  if row.nil?
        end

        if next_line_check
          row_before = nearest_basis_row_from(row, false)
          if row_before && @lines[row_before] =~ @indenters_next_line
            row = row_before
            next
          end
        end

        break
      end

      row
    end

    def parsed_indent( opts = {} )
      row        = opts.fetch( :row,        @last_row )
      do_display = opts.fetch( :do_display, true )
      undoable   = opts.fetch( :undoable,   true )
      cursor_eol = opts.fetch( :cursor_eol, false )

      if row == 0 || @lines[ row ] =~ @settings[ "lang.#{@language}.indent.not_indented" ]
        level = 0
      else
        basis_row = nearest_basis_row_from(row)

        if basis_row.nil?
          level = 0
        else
          # @lines[basis_row] += " // x"
          level = indentation_level(basis_row)

          prev_line = @lines[basis_row]
          line = @lines[row]

          if @preventers
            prev_line = prev_line.gsub( @preventers, "" )
            line = line.gsub( @preventers, "" )
          end

          indenter_index = (prev_line =~ @indenters)
          nl_indenter_index = (prev_line =~ @indenters_next_line)

          if nl_indenter_index && basis_row == row-1
            level += 1
          elsif indenter_index
            level += 1
            unindenter_index = (prev_line =~ @unindenters)
            if unindenter_index && unindenter_index != indenter_index
              level -= 1
            end
          end

          if line =~ @unindenters
            level -= 1
          end
        end
      end

      set_indent  row, level, do_display: do_display, undoable: undoable, cursor_eol: cursor_eol
    end

    def indent( row = @last_row, do_display = DO_DISPLAY )
      level = indentation_level( row, DONT_USE_INDENT_IGNORE )
      set_indent  row, level + 1, do_display: do_display
    end

    def unindent( row = @last_row, do_display = DO_DISPLAY )
      level = indentation_level( row, DONT_USE_INDENT_IGNORE )
      set_indent  row, level - 1, do_display: do_display
    end

  end

end
