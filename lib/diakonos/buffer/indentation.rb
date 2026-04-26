module Diakonos

  class Buffer

    def indent( row = @last_row, do_display = DO_DISPLAY )
      level = indentation_level( row, DONT_USE_INDENT_IGNORE )
      set_indent_leveled  row:, level: level + 1, do_display:
    end

    def indentation_level( row, use_indent_ignore = USE_INDENT_IGNORE )
      line = @lines[ row ]

      if use_indent_ignore
        if line =~ /^[\s#{@indent_ignore_charset}]*$/ || line == ""
          level = 0
        else
          whitespace_prefix = line[ /^([\s#{@indent_ignore_charset}]+)[^\s#{@indent_ignore_charset}]/, 1 ]
          if whitespace_prefix
            whitespace = whitespace_prefix.expand_tabs( @tab_size )
            level = whitespace.length / @indent_size
            if @indent_roundup && ( whitespace.length % @indent_size > 0 )
              level += 1
            end
          else
            level = 0
          end
        end
      else
        whitespace_prefix = line[ /^([\s]+)/, 1 ]
        if whitespace_prefix
          whitespace = whitespace_prefix.expand_tabs( @tab_size )
          level = whitespace.length / @indent_size
          if @indent_roundup && ( whitespace.length % @indent_size > 0 )
            level += 1
          end
        else
          level = 0
        end
      end

      level
    end

    # @param starting_row [Integer]
    # @param next_line_check [Boolean]
    # @return [Integer]
    def nearest_basis_row_from(starting_row, next_line_check: true)
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
          row_before = nearest_basis_row_from(row, next_line_check: false)
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
      row = opts.fetch( :row, @last_row )
      do_display = opts.fetch( :do_display, true )
      undoable = opts.fetch( :undoable, true )
      cursor_eol = opts.fetch( :cursor_eol, false )

      if @indent_align
        parsed_indent_aligned(cursor_eol:, do_display:, row:, undoable:)
      else
        parsed_indent_leveled(cursor_eol:, do_display:, row:, undoable:)
      end
    end

    def tab_expanded_column( col, row )
      delta = 0
      line = @lines[row]

      for i in 0...col
        if line[i] == "\t"
          delta += (
            @tab_size - (
              (i+delta) % @tab_size
            )
          ) - 1
        end
      end

      col + delta
    end

    def unindent( row = @last_row, do_display = DO_DISPLAY )
      level = indentation_level( row, DONT_USE_INDENT_IGNORE )
      set_indent_leveled  row:, level: level - 1, do_display:
    end

    # Given an opener hash { row:, col:, char: }, compute the target column
    # for a new line whose enclosing opener is the given opener.
    private def alignment_column_for_opener( opener )
      # TODO: This should maybe be config, not hard-coded
      if opener[:char] == '('
        alignment_column_for_paren_opener(
          opener_col:    opener[:col],
          raw_line:      @lines[ opener[:row] ],
          stripped_line: blank_out_preventers( @lines[ opener[:row] ] ),
        )
      else
        opener[:col] + 1
      end
    end

    private def alignment_column_for_paren_opener( opener_col:, raw_line:, stripped_line: )
      stripped_text_after_opener = String(
        stripped_line[ (opener_col + 1).. ]
      )
      first_non_space = stripped_text_after_opener.index( /\S/ )

      if first_non_space.nil?
        result = opener_col + 2
      else
        content_col = opener_col + 1 + first_non_space

        tail = stripped_text_after_opener[ first_non_space.. ]
        first_token = tail[ /\A[^\s)\]}]+/ ] || ""

        if first_token =~ @indent_align_special_forms
          result = opener_col + 2
        else
          result = next_line_indent_col(
            first_token_end: content_col + first_token.length,
            opener_col:,
            raw_line:,
          )
        end
      end

      result
    end

    # Returns the column at which row's leading whitespace should end under
    # bracket-alignment rules, or nil if no alignment applies.
    private def alignment_target_column( row )
      opener = enclosing_opener(row)

      if opener
        stripped = blank_out_preventers( @lines[ row ] ).lstrip

        if stripped =~ /\A[)\]}]/
          opener[:col]
        else
          alignment_column_for_opener( opener )
        end
      end
    end

    # Rewrite the leading whitespace of row so that content begins at the given
    # absolute indentation column. Shared core of the aligned/leveled setters.
    private def apply_indentation( row:, indentation:, do_display:, undoable:, cursor_eol: )
      effective_indentation = indentation
      split_pattern = /^([\s#{@indent_ignore_charset}]*)(.*)$/

      row_text = @lines[row]
      current_indent_text = String(
        row_text[split_pattern, 1]
      ).gsub(/\t/, ' ' * @tab_size)
      rest = String(
        row_text[split_pattern, 2]
      )

      if current_indent_text.length >= effective_indentation
        indent_text = current_indent_text[0...effective_indentation]
      else
        indent_text = current_indent_text + " " * ( effective_indentation - current_indent_text.length )
      end

      if @settings[ "lang.#{@language}.indent.using_tabs" ]
        num_tabs = 0
        indent_text.gsub!( / {#{@tab_size}}/ ) do
          num_tabs += 1
          "\t"
        end
        effective_indentation -= num_tabs * ( @tab_size - 1 )
      end

      if do_display && undoable
        take_snapshot(typing: true)
      end

      @lines[row] = indent_text + rest

      if do_display
        cursor_to(
          row,
          cursor_eol ? @lines[row].length : effective_indentation
        )
      end

      set_modified do_display, modified_from_line: row
    end

    # Scan backward from row-1 for the innermost unmatched opener bracket,
    # respecting preventers. Returns { row:, col:, char: } or nil.
    private def enclosing_opener( row )
      opener = nil
      depth = 0
      r = row - 1

      while r >= 0 && opener.nil?
        line = blank_out_preventers( @lines[ r ] )
        scan = scan_row_for_opener( line:, row_index: r, initial_depth: depth )
        opener = scan[:opener]
        depth = scan[:depth]

        r -= 1
      end

      opener
    end

    private def last_match_index(str, pattern)
      if pattern
        str.scan(pattern)

        Regexp.last_match&.begin(0)
      end
    end

    # Compute the level-based indentation for row using the classic
    # indenter/unindenter analysis from the nearest basis row.
    private def level_based_indent( row )
      basis_row = nearest_basis_row_from( row )

      if basis_row.nil?
        level = 0
      else
        level = indentation_level( basis_row )
        prev_line = @lines[ basis_row ]
        line = @lines[ row ]

        if @preventers
          prev_line = prev_line.gsub( @preventers, "" )
          line = line.gsub( @preventers, "" )
        end

        level += level_delta_from_prev( prev_line:, basis_row:, row: )
        level += level_delta_from_current( line )
      end

      level
    end

    private def level_delta_from_current( line )
      delta = 0
      unindenter_index = ( line =~ @unindenters )

      if unindenter_index
        indenter_index = ( line =~ @indenters )
        if indenter_index.nil? || unindenter_index <= indenter_index
          delta = -1
        end
      end

      delta
    end

    private def level_delta_from_prev( prev_line:, basis_row:, row: )
      delta = 0
      nl_indenter_index = ( prev_line =~ @indenters_next_line )

      if nl_indenter_index && basis_row == row - 1
        delta = 1
      elsif prev_line =~ @indenters
        last_indenter = last_match_index( prev_line, @indenters )
        last_unindenter = last_match_index( prev_line, @unindenters )
        if last_unindenter.nil? || last_indenter >= last_unindenter
          delta = 1
        end
      end

      delta
    end

    # Find first argument column on the raw opener line (preventers would have
    # stripped strings to spaces, which would hide string arguments).
    # Returns opener_col + 2 (body indent) if no argument is found on the line.
    private def next_line_indent_col( first_token_end:, opener_col:, raw_line: )
      after_first_token_raw = String( raw_line[ first_token_end.. ] )
      second_token_offset = after_first_token_raw.index( /\S/ )

      if second_token_offset
        first_token_end + second_token_offset
      else
        opener_col + 2
      end
    end

    private def parsed_indent_aligned(cursor_eol:, do_display:, row:, undoable:)
      column = 0
      if row_eligible_for_reindent?( row )
        column = alignment_target_column( row ) || 0
      end

      set_indent_aligned( row:, column:, do_display:, undoable:, cursor_eol: )
    end

    private def parsed_indent_leveled(cursor_eol:, do_display:, row:, undoable:)
      level = 0
      if row_eligible_for_reindent?( row )
        level = level_based_indent( row )
      end

      set_indent_leveled( row:, level:, do_display:, undoable:, cursor_eol: )
    end

    private def row_eligible_for_reindent?( row )
      row > 0 &&
      @lines[ row ] !~ @settings[ "lang.#{@language}.indent.not_indented" ]
    end

    # Scan one line right-to-left for an unmatched opener, given an incoming
    # nesting depth accumulated from lines scanned after this one. Returns
    # { opener: {row:, col:, char:} | nil, depth: updated_depth }.
    private def scan_row_for_opener( line:, row_index:, initial_depth: )
      opener = nil
      depth = initial_depth
      col = line.length - 1

      while col >= 0 && opener.nil?
        c = line[ col ]

        if ')]}'.include?( c )
          depth += 1
        elsif '([{'.include?( c )
          if depth > 0
            depth -= 1
          else
            opener = { row: row_index, col:, char: c }
          end
        end

        col -= 1
      end

      { opener:, depth: }
    end

    private def set_indent_aligned( row:, column:, do_display: true, undoable: true, cursor_eol: false )
      apply_indentation(
        row:,
        indentation: column,
        do_display:,
        undoable:,
        cursor_eol:,
      )
    end

    private def set_indent_leveled( row:, level:, do_display: true, undoable: true, cursor_eol: false )
      apply_indentation(
        row:,
        indentation: @indent_size * [ level, 0 ].max,
        do_display:,
        undoable:,
        cursor_eol:,
      )
    end

    # Replace preventer-matched content with same-length spaces, preserving
    # column positions for downstream bracket-scanning.
    private def blank_out_preventers(line)
      if @preventers
        line.gsub(@preventers) { |m|
          ' ' * m.length
        }
      else
        line
      end
    end

  end

end
