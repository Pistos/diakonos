module Diakonos

  class Buffer
    attr_reader :name, :original_language, :changing_selection, :read_only,
      :tab_size, :selection_mode
    attr_writer :desired_column, :read_only

    TYPING                 = true
    STOPPED_TYPING         = true
    STILL_TYPING           = false
    NO_SNAPSHOT            = true
    DO_DISPLAY             = true
    DONT_DISPLAY           = false
    READ_ONLY              = true
    READ_WRITE             = false
    ROUND_DOWN             = false
    ROUND_UP               = true
    PAD_END                = true
    DONT_PAD_END           = false
    MATCH_CLOSE            = true
    MATCH_ANY              = false
    START_FROM_BEGINNING   = -1
    DO_PITCH_CURSOR        = true
    DONT_PITCH_CURSOR      = false
    STRIP_LINE             = true
    DONT_STRIP_LINE        = false
    USE_INDENT_IGNORE      = true
    DONT_USE_INDENT_IGNORE = false
    WORD_REGEXP            = /\w+/

    # Set name to nil to create a buffer that is not associated with a file.
    # @param [Hash] options
    # @option options [String] 'filepath'
    #   A file path (which is expanded internally)
    # @option options [Boolean] 'read_only' (READ_WRITE)
    #   Whether the buffer should be protected from modification
    # @option options [Hash] 'cursor'
    #   A Hash containing 'row' and/or 'col' indicating where the cursor should
    #   initially be placed.  Defaults: 0 and 0
    # @option options [Hash] 'display'
    #   A Hash containing 'top_line' and 'left_column' indicating where the view
    #   should be positioned in the file.  Defaults: 0 and 0
    # @see READ_WRITE
    # @see READ_ONLY
    def initialize( options = {} )
      @name = options[ 'filepath' ]
      @modified = false
      @last_modification_check = Time.now

      @buffer_states = Array.new
      @cursor_states = Array.new
      if @name.nil?
        @lines = Array.new
        @lines[ 0 ] = ""
      else
        @name = File.expand_path( @name )
        if FileTest.exists? @name
          @lines = IO.readlines( @name )
          if ( @lines.length == 0 ) or ( @lines[ -1 ][ -1..-1 ] == "\n" )
            @lines.push ""
          end
          @lines = @lines.collect do |line|
            line.chomp
          end
        else
          @lines = Array.new
          @lines[ 0 ] = ""
        end
      end

      @current_buffer_state = 0

      options[ 'display' ] ||= Hash.new
      @top_line = options[ 'display' ][ 'top_line' ] || 0
      @left_column = options[ 'display' ][ 'left_column' ] ||  0
      @desired_column = @left_column
      @mark_anchor = nil
      @text_marks = Hash.new
      @selection_mode = :normal
      @last_search_regexps = Array( options['last_search_regexps'] ).map { |r| Regexp.new(r) }
      @highlight_regexp = nil
      @last_search = nil
      @changing_selection = false
      @typing = false
      options[ 'cursor' ] ||= Hash.new
      @last_col = options[ 'cursor' ][ 'col' ] || 0
      @last_row = options[ 'cursor' ][ 'row' ] || 0
      @last_screen_y = @last_row - @top_line
      @last_screen_x = @last_col - @left_column
      @last_screen_col = @last_screen_x
      @read_only = options[ 'read_only' ] || READ_WRITE
      @bookmarks = Array.new
      @lang_stack = Array.new

      configure

      if @settings[ "convert_tabs" ]
        tabs_subbed = false
        @lines.collect! do |line|
          new_line = line.expand_tabs( @tab_size )
          tabs_subbed = ( tabs_subbed or new_line != line )
          # Return value for collect:
          new_line
        end
        @modified = ( @modified or tabs_subbed )
        if tabs_subbed
          $diakonos.set_iline "(spaces substituted for tab characters)"
        end
      end

      @buffer_states[ @current_buffer_state ] = @lines
      @cursor_states[ @current_buffer_state ] = [ @last_row, @last_col ]
    end

    def configure(
      language = (
        $diakonos.get_language_from_shabang( @lines[ 0 ] ) or
        $diakonos.get_language_from_name( @name ) or
        LANG_TEXT
      )
    )
      reset_display
      set_language language
      @original_language = @language
    end

    def reset_display
      @win_main = $diakonos.win_main
      @win_line_numbers = $diakonos.win_line_numbers
    end

    def set_language( language )
      @settings = $diakonos.settings
      @language = language
      @surround_pairs = $diakonos.surround_pairs[ @language ]
      @token_regexps = $diakonos.token_regexps[ @language ]
      @close_token_regexps = $diakonos.close_token_regexps[ @language ]
      @token_formats = $diakonos.token_formats[ @language ]
      @indenters = $diakonos.indenters[ @language ]
      @indenters_next_line = $diakonos.indenters_next_line[ @language ]
      @unindenters = $diakonos.unindenters[ @language ]
      @preventers = @settings[ "lang.#{@language}.indent.preventers" ]
      @closers = $diakonos.closers[ @language ] || Hash.new
      @auto_indent = @settings[ "lang.#{@language}.indent.auto" ]
      @indent_size = ( @settings[ "lang.#{@language}.indent.size" ] || 4 )
      @indent_roundup = @settings[ "lang.#{@language}.indent.roundup" ].nil? ? true : @settings[ "lang.#{@language}.indent.roundup" ]
      @indent_closers = @settings[ "lang.#{@language}.indent.closers" ].nil? ? false : @settings[ "lang.#{@language}.indent.closers" ]
      @default_formatting = ( @settings[ "lang.#{@language}.format.default" ] || Curses::A_NORMAL )
      @selection_formatting = ( @settings[ "lang.#{@language}.format.selection" ] || Curses::A_REVERSE )
      @indent_ignore_charset = ( @settings[ "lang.#{@language}.indent.ignore.charset" ] || "" )
      @tab_size = ( @settings[ "lang.#{@language}.tabsize" ] || DEFAULT_TAB_SIZE )
    end

    def [] ( arg )
      @lines[ arg ]
    end

    def == (other)
      return false  if other.nil?
      @name == other.name
    end

    def length
      @lines.length
    end

    def to_a
      @lines.dup
    end

    def modified?
      @modified
    end

    def nice_name
      @name || @settings[ "status.unnamed_str" ]
    end

    def replace_char( c )
      row = @last_row
      col = @last_col
      take_snapshot TYPING
      @lines[ row ][ col ] = c
      set_modified
    end

    def insert_char( c )
      row = @last_row
      col = @last_col
      take_snapshot( TYPING )
      line = @lines[ row ]
      @lines[ row ] = line[ 0...col ] + c.chr + line[ col..-1 ]
      set_modified
    end

    def insert_string( str )
      row = @last_row
      col = @last_col
      take_snapshot( TYPING )
      line = @lines[ row ]
      @lines[ row ] = line[ 0...col ] + str + line[ col..-1 ]
      set_modified
    end

    def surround( text, parenthesis )
      pattern, pair = @surround_pairs.select { |r, p| parenthesis =~ r }.to_a[ 0 ]

      if pair.nil?
        $diakonos.set_iline "No matching parentheses pair found."
        nil
      else
        pair.map! do |paren|
          parenthesis.gsub( pattern, paren )
        end
        pair[ 0 ] + text.join( "\n" ) + pair[ 1 ]
      end
    end

    def join_lines_upward( row = @last_row, strip = DONT_STRIP_LINE )
      return false  if row == 0

      take_snapshot

      line       = @lines.delete_at( row )
      old_line   = @lines[ row-1 ]

      new_x_pos  = old_line.length

      if strip
        line.strip!

        # Only prepend a space if the line above isn't empty.
        if ! old_line.strip.empty?
          line = ' ' + line
          new_x_pos += 1
        end
      end

      @lines[ row-1 ] << line

      cursor_to( row-1, new_x_pos )

      set_modified
    end

    def join_lines( row = @last_row, strip = DONT_STRIP_LINE )
      take_snapshot( TYPING )
      next_line = @lines.delete_at( row + 1 )
      return false  if next_line.nil?

      if strip
        next_line = ' ' + next_line.strip
      end
      @lines[ row ] << next_line
      set_modified
    end

    def close_code
      line = @lines[ @last_row ]
      @closers.each_value do |h|
        h[ :regexp ] =~ line
        lm = Regexp.last_match
        if lm
          str = case h[ :closer ]
          when String
            if lm[ 1 ].nil?
              h[ :closer ]
            else
              lm[ 1 ].gsub(
                Regexp.new( "(#{ Regexp.escape( lm[1] ) })" ),
                h[ :closer ]
              )
            end
          when Proc
            h[ :closer ].call( lm ).to_s
          end
          r, c = @last_row, @last_col
          paste str, !TYPING, @indent_closers
          cursor_to r, c
          if /%_/ === str
            find [/%_/], direction: :down, replacement: '', auto_choice: CHOICE_YES_AND_STOP
          end
        end
      end
    end

    def collapse_whitespace
      if selection_mark
        remove_selection DONT_DISPLAY
      end

      line = @lines[ @last_row ]
      head = line[ 0...@last_col ]
      tail = line[ @last_col..-1 ]
      new_head = head.sub( /\s+$/, '' )
      new_line = new_head + tail.sub( /^\s+/, ' ' )
      if new_line != line
        take_snapshot( TYPING )
        @lines[ @last_row ] = new_line
        cursor_to( @last_row, @last_col - ( head.length - new_head.length ) )
        set_modified
      end
    end

    def columnize( delimiter = /=>?|:|,/, num_spaces_padding = 1 )
      take_snapshot

      lines = selected_lines
      column_width = 0
      lines.each do |line|
        pos = ( line =~ delimiter )
        if pos
          column_width = [ pos, column_width ].max
        end
      end

      padding = ' ' * num_spaces_padding
      one_modified = false

      lines.each do |line|
        old_line = line.dup
        if line =~ /^(.+?)(#{delimiter.source})(.*)$/
          pre = $1
          del = $2
          post = $3
          if pre !~ /\s$/
            del = " #{del}"
          end
          if post !~ /^\s/
            del = "#{del} "
          end
          del.sub!( /^\s+/, ' ' * num_spaces_padding )
          del.sub!( /\s+$/, ' ' * num_spaces_padding )
          line.replace( ( "%-#{column_width}s" % pre ) + del + post )
        end
        one_modified ||= ( line != old_line )
      end

      if one_modified
        set_modified
      end
    end

    def comment_out
      take_snapshot
      one_modified = false
      selected_lines.each do |line|
        next  if line.strip.empty?
        old_line = line.dup
        line.gsub!( /^(\s*)/, "\\1" + @settings[ "lang.#{@language}.comment_string" ].to_s )
        line << @settings[ "lang.#{@language}.comment_close_string" ].to_s
        one_modified ||= ( line != old_line )
      end
      if one_modified
        set_modified
      end
    end

    def uncomment
      take_snapshot
      comment_string = Regexp.escape( @settings[ "lang.#{@language}.comment_string" ].to_s )
      comment_close_string = Regexp.escape( @settings[ "lang.#{@language}.comment_close_string" ].to_s )
      one_modified = false
      selected_lines.each do |line|
        old_line = line.dup
        line.gsub!( /^(\s*)#{comment_string}/, "\\1" )
        line.gsub!( /#{comment_close_string}$/, '' )
        one_modified ||= ( line != old_line )
      end
      if one_modified
        set_modified
      end
    end

    def carriage_return
      take_snapshot
      row = @last_row
      col = @last_col
      @lines = @lines[ 0...row ] +
        [ @lines[ row ][ 0...col ] ] +
        [ @lines[ row ][ col..-1 ] ] +
        @lines[ (row+1)..-1 ]
      cursor_to( row + 1, 0 )
      if @auto_indent
        parsed_indent  undoable: false
      end
      set_modified
    end

    def line_at( y )
      row = @top_line + y
      if row < 0
        nil
      else
        @lines[ row ]
      end
    end

    def current_line
      @lines[ @last_row ]
    end

    # Returns true iff the given column, x, is less than the length of the given line, y.
    def in_line( x, y )
      x + @left_column < line_at( y ).length
    end

    # Translates the window column, x, to a buffer-relative column index.
    def column_of( x )
      @left_column + x
    end

    # Translates the window row, y, to a buffer-relative row index.
    def row_of( y )
      @top_line + y
    end

    # Returns nil if the row is off-screen.
    def row_to_y( row )
      return nil if row.nil?
      y = row - @top_line
      y = nil if ( y < 0 ) or ( y > @top_line + $diakonos.main_window_height - 1 )
      y
    end

    # Returns nil if the column is off-screen.
    def column_to_x( col )
      return nil if col.nil?
      x = col - @left_column
      x = nil if ( x < 0 ) or ( x > @left_column + Curses::cols - 1 )
      x
    end

    def current_row
      @last_row
    end

    def current_column
      @last_col
    end

    def pan_view_to( left_column, do_display = DO_DISPLAY )
      @left_column = [ left_column, 0 ].max
      record_mark_start_and_end
      display  if do_display
    end

    # Returns the amount the view was actually panned.
    def pan_view( x = 1, do_display = DO_DISPLAY )
      old_left_column = @left_column
      pan_view_to( @left_column + x, do_display )
      @left_column - old_left_column
    end

    def pitch_view_to( new_top_line, do_pitch_cursor = DONT_PITCH_CURSOR, do_display = DO_DISPLAY )
      old_top_line = @top_line

      if new_top_line < 0
        @top_line = 0
      elsif new_top_line + $diakonos.main_window_height > @lines.length
        @top_line = [ @lines.length - $diakonos.main_window_height, 0 ].max
      else
        @top_line = new_top_line
      end

      old_row = @last_row
      old_col = @last_col

      changed = ( @top_line - old_top_line )
      if changed != 0 && do_pitch_cursor
        @last_row += changed
      end

      height = [ $diakonos.main_window_height, @lines.length ].min

      @last_row = @last_row.fit( @top_line, @top_line + height - 1 )
      if @last_row - @top_line < @settings[ "view.margin.y" ]
        @last_row = @top_line + @settings[ "view.margin.y" ]
        @last_row = @last_row.fit( @top_line, @top_line + height - 1 )
      elsif @top_line + height - 1 - @last_row < @settings[ "view.margin.y" ]
        @last_row = @top_line + height - 1 - @settings[ "view.margin.y" ]
        @last_row = @last_row.fit( @top_line, @top_line + height - 1 )
      end
      @last_col = @last_col.fit( @left_column, [ @left_column + Curses::cols - 1, @lines[ @last_row ].length ].min )
      @last_screen_y = @last_row - @top_line
      @last_screen_x = tab_expanded_column( @last_col, @last_row ) - @left_column

      record_mark_start_and_end

      if changed != 0
        if ! @changing_selection && selecting?
          remove_selection DONT_DISPLAY
        end

        highlight_matches
        if $diakonos.there_was_non_movement
          $diakonos.push_cursor_state( old_top_line, old_row, old_col )
        end
      end

      display  if do_display

      changed
    end

    # Returns the amount the view was actually pitched.
    def pitch_view( y = 1, do_pitch_cursor = DONT_PITCH_CURSOR, do_display = DO_DISPLAY )
      pitch_view_to( @top_line + y, do_pitch_cursor, do_display )
    end

    def wrap_paragraph
      start_row = end_row = cursor_row = @last_row
      cursor_col = @last_col
      until start_row == 0 || @lines[ start_row - 1 ].strip == ''
        start_row -= 1
      end
      until end_row == @lines.size || @lines[ end_row ].strip == ''
        end_row += 1
      end

      lines = []
      line = ''
      words = @lines[ start_row...end_row ].join( ' ' ).scan( /\S+/ )
      words.each do |word|
        if word =~ /^[a-z']+[.!?]$/
          word = "#{word} "
        end
        if line.length + word.length + 1 > ( @settings[ "lang.#{@language}.wrap_margin" ] || 80 )
          lines << line.strip
          line = ''
        end
        line << " #{word}"
      end
      line.strip!
      if ! line.empty?
        lines << line
      end
      if @lines[ start_row...end_row ] != lines
        take_snapshot
        @lines[ start_row...end_row ] = lines
        set_modified
        cursor_to start_row + lines.length, lines[-1].length
      end
    end

    def context
      retval = Array.new
      row = @last_row
      clevel = indentation_level( row )
      while row > 0 && clevel < 0
        row = row - 1
        clevel = indentation_level( row )
      end
      clevel = 0  if clevel < 0
      while row > 0
        row = row - 1
        line = @lines[ row ]
        if ! line.strip.empty? && ( line !~ @settings[ "lang.#{@language}.context.ignore" ] )
          level = indentation_level( row )
          if level < clevel and level > -1
            retval.unshift line
            clevel = level
            break  if clevel == 0
          end
        end
      end
      retval
    end

    def set_type( type )
      return false  if type.nil?
      configure( type )
      display
      true
    end

    def word_under_cursor
      pos = word_under_cursor_pos
      return  if pos.nil?

      col1 = pos[ 0 ][ 1 ]
      col2 = pos[ 1 ][ 1 ]
      @lines[ @last_row ][ col1...col2 ]
    end

    def word_under_cursor_pos( options = {} )
      or_after = options[:or_after]
      @lines[ @last_row ].scan( WORD_REGEXP ) do |match_text|
        last_match = Regexp.last_match
        if (
          last_match.begin( 0 ) <= @last_col && @last_col < last_match.end( 0 ) ||
          or_after && last_match.begin(0) > @last_col
        )
          return [
            [ @last_row, last_match.begin( 0 ) ],
            [ @last_row, last_match.end( 0 ) ],
          ]
        end
      end

      nil
    end

    def word_before_cursor
      word = nil

      @lines[ @last_row ].scan( WORD_REGEXP ) do |match_text|
        last_match = Regexp.last_match
        if last_match.begin( 0 ) <= @last_col && @last_col <= last_match.end( 0 )
          word = match_text
          break
        end
      end

      word
    end
    # TODO word_before_cursor_pos

    # Returns an array of lines of the current paragraph.
    def paragraph_under_cursor
      ( first, _ ), ( last, _ ) = paragraph_under_cursor_pos
      @lines[ first..last ]
    end

    # Returns the coordinates of the first and last line of the current
    # paragraph.
    def paragraph_under_cursor_pos
      if @lines[ @last_row ] =~ /^\s*$/
        return [
          [ @last_row, 0 ],
          [ @last_row, @lines[ @last_row ].length - 1 ]
        ]
      end

      upper_boundary = 0
      lower_boundary = @lines.size - 1

      @last_row.downto( 0 ) do |i|
        line = @lines[ i ]
        if line =~ /^\s*$/
          upper_boundary = i + 1
          break
        end
      end

      @last_row.upto( @lines.size - 1 ) do |i|
        line = @lines[ i ]
        if line =~ /^\s*$/
          lower_boundary = i - 1
          break
        end
      end

      [
        [ upper_boundary, 0 ],
        [ lower_boundary, @lines[ lower_boundary ].length - 1 ]
      ]
    end
    # TODO paragraph_before_cursor(_pos)?

    def words( filter_regexp = nil )
      w = @lines.join( ' ' ).scan( WORD_REGEXP )
      filter_regexp ? w.grep( filter_regexp ) : w
    end

  end

end
