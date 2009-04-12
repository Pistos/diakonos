module Diakonos

  class Buffer

    # x and y are given window-relative, not buffer-relative.
    def delete
      if selection_mark
        delete_selection
      else
        row = @last_row
        col = @last_col
        if ( row >= 0 ) and ( col >= 0 )
          line = @lines[ row ]
          if col == line.length
            if row < @lines.length - 1
              # Delete newline, and concat next line
              join_lines( row )
              cursor_to( @last_row, @last_col )
            end
          else
            takeSnapshot( TYPING )
            @lines[ row ] = line[ 0...col ] + line[ (col + 1)..-1 ]
            set_modified
          end
        end
      end
    end

    def delete_line
      remove_selection( DONT_DISPLAY )  if selection_mark

      row = @last_row
      takeSnapshot
      retval = nil
      if @lines.length == 1
        retval = @lines[ 0 ]
        @lines[ 0 ] = ""
      else
        retval = @lines[ row ]
        @lines.delete_at row
      end
      cursor_to( row, 0 )
      set_modified

      retval
    end

    def delete_to_eol
      remove_selection( DONT_DISPLAY )  if selection_mark

      row = @last_row
      col = @last_col

      takeSnapshot
      if @settings[ 'delete_newline_on_delete_to_eol' ] and col == @lines[ row ].size
        next_line = @lines.delete_at( row + 1 )
        @lines[ row ] << next_line
        retval = [ "\n" ]
      else
        retval = [ @lines[ row ][ col..-1 ] ]
        @lines[ row ] = @lines[ row ][ 0...col ]
      end
      set_modified

      retval
    end

    def delete_from_to( row_from, col_from, row_to, col_to )
      takeSnapshot
      if row_to == row_from
        retval = [ @lines[ row_to ].slice!( col_from, col_to - col_from ) ]
      else
        pre_head = @lines[ row_from ][ 0...col_from ]
        post_tail = @lines[ row_to ][ col_to..-1 ]
        head = @lines[ row_from ].slice!( col_from..-1 )
        tail = @lines[ row_to ].slice!( 0...col_to )
        retval = [ head ] + @lines.slice!( row_from + 1, row_to - row_from ) + [ tail ]
        @lines[ row_from ] = pre_head + post_tail
      end
      set_modified
      retval
    end

    def delete_to( char )
      remove_selection( DONT_DISPLAY )  if selection_mark

      first_row = row = @last_row
      index = @lines[ @last_row ].index( char, @last_col+1 )

      while row < @lines.length - 1 && index.nil?
        row += 1
        index = @lines[ row ].index( char )
      end

      if index
        delete_from_to( first_row, @last_col, row, index )
      end
    end

    def delete_to_and_from( char )
      remove_selection( DONT_DISPLAY )  if selection_mark

      start_char = end_char = char
      case char
        when '('
          end_char = ')'
        when '{'
          end_char = '}'
        when '['
          end_char = ']'
        when '<'
          end_char = '>'
        when ')'
          start_char = '('
        when '}'
          start_char = '{'
        when ']'
          start_char = '['
        when '>'
          start_char = '<'
      end

      row = @last_row
      start_index = @lines[ @last_row ].rindex( start_char, @last_col )
      while row > 0 && start_index.nil?
        row -= 1
        start_index = @lines[ row ].rindex( start_char )
      end
      start_row = row

      row = @last_row
      end_index = @lines[ row ].index( end_char, @last_col+1 )
      while row < @lines.length - 1 && end_index.nil?
        row += 1
        end_index = @lines[ row ].index( end_char )
      end
      end_row = row

      if start_index && end_index
        cursor_to( start_row, start_index+1 )
        delete_from_to( start_row, start_index+1, end_row, end_index )
      end
    end

  end

end