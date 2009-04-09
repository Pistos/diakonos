module Diakonos

  class Buffer
    attr_reader :name, :key, :original_language, :changing_selection, :read_only,
      :last_col, :last_row, :tab_size, :last_screen_x, :last_screen_y, :last_screen_col,
      :selection_mode
    attr_writer :desired_column, :read_only

    SELECTION = 0  # Selection mark is the first element of the @text_marks array
    TYPING = true
    STOPPED_TYPING = true
    STILL_TYPING = false
    NO_SNAPSHOT = true
    DO_DISPLAY = true
    DONT_DISPLAY = false
    READ_ONLY = true
    READ_WRITE = false
    ROUND_DOWN = false
    ROUND_UP = true
    PAD_END = true
    DONT_PAD_END = false
    MATCH_CLOSE = true
    MATCH_ANY = false
    START_FROM_BEGINNING = -1
    DO_PITCH_CURSOR = true
    DONT_PITCH_CURSOR = false
    CLEAR_STACK_POINTER = true
    DONT_CLEAR_STACK_POINTER = false
    STRIP_LINE = true
    DONT_STRIP_LINE = false
    USE_INDENT_IGNORE = true
    DONT_USE_INDENT_IGNORE = false

    # Set name to nil to create a buffer that is not associated with a file.
    def initialize( diakonos, name, key, read_only = false )
      @diakonos = diakonos
      @name = name
      @key = key
      @modified = false
      @last_modification_check = Time.now

      @buffer_states = Array.new
      @cursor_states = Array.new
      if @name
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
      else
        @lines = Array.new
        @lines[ 0 ] = ""
      end
      @current_buffer_state = 0

      @top_line = 0
      @left_column = 0
      @desired_column = 0
      @mark_anchor = nil
      @text_marks = Array.new
      @selection_mode = :normal
      @last_search_regexps = nil
      @highlight_regexp = nil
      @last_search = nil
      @changing_selection = false
      @typing = false
      @last_col = 0
      @last_screen_col = 0
      @last_screen_y = 0
      @last_screen_x = 0
      @last_row = 0
      @read_only = read_only
      @bookmarks = Array.new
      @lang_stack = Array.new
      @cursor_stack = Array.new
      @cursor_stack_pointer = nil

      configure

      if @settings[ "convert_tabs" ]
        tabs_subbed = false
        @lines.collect! do |line|
          new_line = line.expandTabs( @tab_size )
          tabs_subbed = ( tabs_subbed or new_line != line )
          # Return value for collect:
          new_line
        end
        @modified = ( @modified or tabs_subbed )
        if tabs_subbed
          @diakonos.setILine "(spaces substituted for tab characters)"
        end
      end

      @buffer_states[ @current_buffer_state ] = @lines
      @cursor_states[ @current_buffer_state ] = [ @last_row, @last_col ]
    end

    def configure(
      language = (
        @diakonos.getLanguageFromShaBang( @lines[ 0 ] ) or
        @diakonos.getLanguageFromName( @name ) or
        LANG_TEXT
      )
    )
      reset_display
      setLanguage language
      @original_language = @language
    end

    def reset_display
      @win_main = @diakonos.win_main
      @win_line_numbers = @diakonos.win_line_numbers
    end

    def setLanguage( language )
      @settings = @diakonos.settings
      @language = language
      @token_regexps = ( @diakonos.token_regexps[ @language ] or Hash.new )
      @close_token_regexps = ( @diakonos.close_token_regexps[ @language ] or Hash.new )
      @token_formats = ( @diakonos.token_formats[ @language ] or Hash.new )
      @indenters = @diakonos.indenters[ @language ]
      @unindenters = @diakonos.unindenters[ @language ]
      @preventers = @settings[ "lang.#{@language}.indent.preventers" ]
      @closers = @diakonos.closers[ @language ] || Hash.new
      @auto_indent = @settings[ "lang.#{@language}.indent.auto" ]
      @indent_size = ( @settings[ "lang.#{@language}.indent.size" ] or 4 )
      @indent_roundup = @settings[ "lang.#{@language}.indent.roundup" ].nil? ? true : @settings[ "lang.#{@language}.indent.roundup" ]
      @indent_closers = @settings[ "lang.#{@language}.indent.closers" ].nil? ? false : @settings[ "lang.#{@language}.indent.closers" ]
      @default_formatting = ( @settings[ "lang.#{@language}.format.default" ] or Curses::A_NORMAL )
      @selection_formatting = ( @settings[ "lang.#{@language}.format.selection" ] or Curses::A_REVERSE )
      @indent_ignore_charset = ( @settings[ "lang.#{@language}.indent.ignore.charset" ] or "" )
      @tab_size = ( @settings[ "lang.#{@language}.tabsize" ] or DEFAULT_TAB_SIZE )
    end
    protected :setLanguage

    def [] ( arg )
      @lines[ arg ]
    end

    def == (other)
      return false if other.nil?
      key == other.key
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

    def replaceChar( c )
      row = @last_row
      col = @last_col
      takeSnapshot( TYPING )
      @lines[ row ][ col ] = c
      setModified
    end

    def insertChar( c )
      row = @last_row
      col = @last_col
      takeSnapshot( TYPING )
      line = @lines[ row ]
      @lines[ row ] = line[ 0...col ] + c.chr + line[ col..-1 ]
      setModified
    end

    def insertString( str )
      row = @last_row
      col = @last_col
      takeSnapshot( TYPING )
      line = @lines[ row ]
      @lines[ row ] = line[ 0...col ] + str + line[ col..-1 ]
      setModified
    end

    def joinLines( row = @last_row, strip = DONT_STRIP_LINE )
      takeSnapshot( TYPING )
      next_line = @lines.delete_at( row + 1 )
      if strip
        next_line = ' ' + next_line.strip
      end
      @lines[ row ] << next_line
      setModified
    end

    def close_code
      line = @lines[ @last_row ]
      @closers.each_value do |h|
        h[ :regexp ] =~ line
        lm = Regexp.last_match
        if lm
          str = h[ :closer ].call( lm ).to_s
          r, c = @last_row, @last_col
          paste str, @indent_closers
          cursorTo r, c
          if /%_/ === str
            find( [ /%_/ ], :direction => :down, :replacement => '', :auto_choice => CHOICE_YES_AND_STOP )
          end
        end
      end
    end

    def collapseWhitespace
      if selection_mark
        removeSelection DONT_DISPLAY
      end

      line = @lines[ @last_row ]
      head = line[ 0...@last_col ]
      tail = line[ @last_col..-1 ]
      new_head = head.sub( /\s+$/, '' )
      new_line = new_head + tail.sub( /^\s+/, ' ' )
      if new_line != line
        takeSnapshot( TYPING )
        @lines[ @last_row ] = new_line
        cursorTo( @last_row, @last_col - ( head.length - new_head.length ) )
        setModified
      end
    end

    def columnize( delimiter = /=>?|:|,/, num_spaces_padding = 1 )
      takeSnapshot

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
        setModified
      end
    end

    def comment_out
      takeSnapshot
      one_modified = false
      selected_lines.each do |line|
        old_line = line.dup
        line.gsub!( /^(\s*)/, "\\1" + @settings[ "lang.#{@language}.comment_string" ].to_s )
        line << @settings[ "lang.#{@language}.comment_close_string" ].to_s
        one_modified ||= ( line != old_line )
      end
      if one_modified
        setModified
      end
    end

    def uncomment
      takeSnapshot
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
        setModified
      end
    end

    def carriageReturn
      takeSnapshot
      row = @last_row
      col = @last_col
      @lines = @lines[ 0...row ] +
        [ @lines[ row ][ 0...col ] ] +
        [ @lines[ row ][ col..-1 ] ] +
        @lines[ (row+1)..-1 ]
      cursorTo( row + 1, 0 )
      parsedIndent if @auto_indent
      setModified
    end

    def lineAt( y )
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
    def inLine( x, y )
      x + @left_column < lineAt( y ).length
    end

    # Translates the window column, x, to a buffer-relative column index.
    def columnOf( x )
      @left_column + x
    end

    # Translates the window row, y, to a buffer-relative row index.
    def rowOf( y )
      @top_line + y
    end

    # Returns nil if the row is off-screen.
    def rowToY( row )
      return nil if row.nil?
      y = row - @top_line
      y = nil if ( y < 0 ) or ( y > @top_line + @diakonos.main_window_height - 1 )
      y
    end

    # Returns nil if the column is off-screen.
    def columnToX( col )
      return nil if col.nil?
      x = col - @left_column
      x = nil if ( x < 0 ) or ( x > @left_column + Curses::cols - 1 )
      x
    end

    def currentRow
      @last_row
    end

    def currentColumn
      @last_col
    end

    # Returns the amount the view was actually panned.
    def panView( x = 1, do_display = DO_DISPLAY )
      old_left_column = @left_column
      @left_column = [ @left_column + x, 0 ].max
      recordMarkStartAndEnd
      display if do_display
      @left_column - old_left_column
    end

    # Returns the amount the view was actually pitched.
    def pitchView( y = 1, do_pitch_cursor = DONT_PITCH_CURSOR, do_display = DO_DISPLAY )
      old_top_line = @top_line
      new_top_line = @top_line + y

      if new_top_line < 0
        @top_line = 0
      elsif new_top_line + @diakonos.main_window_height > @lines.length
        @top_line = [ @lines.length - @diakonos.main_window_height, 0 ].max
      else
        @top_line = new_top_line
      end

      old_row = @last_row
      old_col = @last_col

      changed = ( @top_line - old_top_line )
      if changed != 0 and do_pitch_cursor
        @last_row += changed
      end

      height = [ @diakonos.main_window_height, @lines.length ].min

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
      @last_screen_x = tabExpandedColumn( @last_col, @last_row ) - @left_column

      recordMarkStartAndEnd

      if changed != 0
        if not @changing_selection and selecting?
          removeSelection( DONT_DISPLAY )
        end

        highlightMatches
        if @diakonos.there_was_non_movement
          pushCursorState( old_top_line, old_row, old_col )
        end
      end

      display if do_display

      changed
    end

    def wrap_paragraph
      start_row = end_row = @last_row
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
      if not line.empty?
        lines << line
      end
      if @lines[ start_row...end_row ] != lines
        @lines[ start_row...end_row ] = lines
        setModified
      end
    end

    def context
      retval = Array.new
      row = @last_row
      clevel = indentation_level( row )
      while row > 0 and clevel < 0
        row = row - 1
        clevel = indentation_level( row )
      end
      clevel = 0 if clevel < 0
      while row > 0
        row = row - 1
        line = @lines[ row ]
        if line !~ @settings[ "lang.#{@language}.context.ignore" ]
          level = indentation_level( row )
          if level < clevel and level > -1
            retval.unshift line
            clevel = level
            break if clevel == 0
          end
        end
      end
      retval
    end

    def setType( type )
      if type
        configure( type )
        display
        true
      end
    end

    def word_under_cursor
      word = nil

      @lines[ @last_row ].scan( /\w+/ ) do |match_text|
        last_match = Regexp.last_match
        if last_match.begin( 0 ) <= @last_col and @last_col < last_match.end( 0 )
          word = match_text
          break
        end
      end

      word
    end

  end

end