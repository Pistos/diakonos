module Diakonos

class Buffer
    attr_reader :name, :key, :modified, :original_language, :changing_selection, :read_only,
        :last_col, :last_row, :tab_size, :last_screen_x, :last_screen_y, :last_screen_col
    attr_writer :desired_column, :read_only

    SELECTION = 0
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

    # Set name to nil to create a buffer that is not associated with a file.
    def initialize( diakonos, name, key, read_only = false )
        @diakonos = diakonos
        @name = name
        @key = key
        @modified = false
        @last_modification_check = Time.now

        @buffer_states = Array.new
        @cursor_states = Array.new
        if @name != nil
            @name = @name.subHome
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
        reset_win_main
        setLanguage language
        @original_language = @language
    end
    
    def reset_win_main
        @win_main = @diakonos.win_main
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
        @indent_closers = @settings[ "lang.#{@language}.indent.closers" ].nil? ? true : @settings[ "lang.#{@language}.indent.closers" ]
        @default_formatting = ( @settings[ "lang.#{@language}.format.default" ] or Curses::A_NORMAL )
        @selection_formatting = ( @settings[ "lang.#{@language}.format.selection" ] or Curses::A_REVERSE )
        @indent_ignore_charset = ( @settings[ "lang.#{@language}.indent.ignore.charset" ] or "" )
        @tab_size = ( @settings[ "lang.#{@language}.tabsize" ] or DEFAULT_TAB_SIZE )
    end
    protected :setLanguage

    def [] ( arg )
        return @lines[ arg ]
    end
    
    def == (other)
        return false if other.nil?
        key == other.key
    end

    def length
        return @lines.length
    end

    def nice_name
        return ( @name || @settings[ "status.unnamed_str" ] )
    end

    def display
        return if not @diakonos.do_display
        
        Thread.new do
            #if $profiling
                #RubyProf.start
            #end
                    
            if @diakonos.display_mutex.try_lock
                begin
                    Curses::curs_set 0
                    
                    @continued_format_class = nil
                    
                    @pen_down = true
                    
                    # First, we have to "draw" off-screen, in order to check for opening of
                    # multi-line highlights.
                    
                    # So, first look backwards from the @top_line to find the first opening
                    # regexp match, if any.
                    index = @top_line - 1
                    @lines[ [ 0, @top_line - @settings[ "view.lookback" ] ].max...@top_line ].reverse_each do |line|
                        open_index = -1
                        open_token_class = nil
                        open_match_text = nil
                        
                        open_index, open_token_class, open_match_text = findOpeningMatch( line )
                        
                        if open_token_class != nil
                            @pen_down = false
                            @lines[ index...@top_line ].each do |line|
                                printLine line
                            end
                            @pen_down = true
                            
                            break
                        end
                        
                        index = index - 1
                    end
                    
                    # Draw each on-screen line.
                    y = 0
                    @lines[ @top_line...(@diakonos.main_window_height + @top_line) ].each_with_index do |line, row|
                        @win_main.setpos( y, 0 )
                        printLine line.expandTabs( @tab_size )
                        @win_main.setpos( y, 0 )
                        paintMarks @top_line + row
                        y += 1
                    end
                    
                    # Paint the empty space below the file if the file is too short to fit in one screen.
                    ( y...@diakonos.main_window_height ).each do |y|
                        @win_main.setpos( y, 0 )
                        @win_main.attrset @default_formatting
                        linestr = " " * Curses::cols
                        if @settings[ "view.nonfilelines.visible" ]
                            linestr[ 0 ] = ( @settings[ "view.nonfilelines.character" ] or "~" )
                        end
                        
                        @win_main.addstr linestr
                    end
                    
                    @win_main.setpos( @last_screen_y , @last_screen_x )
                    @win_main.refresh
                    
                    if @language != @original_language
                        setLanguage( @original_language )
                    end
                    
                    Curses::curs_set 1
                rescue Exception => e
                    @diakonos.log( "Display Exception:" )
                    @diakonos.log( e.message )
                    @diakonos.log( e.backtrace.join( "\n" ) )
                    showException e
                end
                @diakonos.display_mutex.unlock
                @diakonos.displayDequeue
            else
                @diakonos.displayEnqueue( self )
            end
            
            #if $profiling
                #result = RubyProf.stop
                #printer = RubyProf::GraphHtmlPrinter.new( result )
                #File.open( "#{ENV['HOME']}/svn/diakonos/profiling/diakonos-profile-#{Time.now.to_i}.html", 'w' ) do |f|
                    #printer.print( f )
                #end
            #end
        end
        
    end

    def findOpeningMatch( line, match_close = true, bos_allowed = true )
        open_index = line.length
        open_token_class = nil
        open_match_text = nil
        match = nil
        match_text = nil
        @token_regexps.each do |token_class,regexp|
            if match = regexp.match( line )
                if match.length > 1
                    index = match.begin 1
                    match_text = match[ 1 ]
                    whole_match_index = match.begin 0
                else
                    whole_match_index = index = match.begin( 0 )
                    match_text = match[ 0 ]
                end
                if ( not regexp.uses_bos ) or ( bos_allowed and ( whole_match_index == 0 ) )
                    if index < open_index
                        if ( ( not match_close ) or @close_token_regexps[ token_class ] != nil )
                            open_index = index
                            open_token_class = token_class
                            open_match_text = match_text
                        end
                    end
                end
            end
        end

        return [ open_index, open_token_class, open_match_text ]
    end

    def findClosingMatch( line_, regexp, bos_allowed = true, start_at = 0 )
        close_match_text = nil
        close_index = nil
        if start_at > 0
            line = line_[ start_at..-1 ]
        else
            line = line_
        end
        line.scan( regexp ) do |m|
            match = Regexp.last_match
            if match.length > 1
                index = match.begin 1
                match_text = match[ 1 ]
            else
                index = match.begin 0
                match_text = match[ 0 ]
            end
            if ( not regexp.uses_bos ) or ( bos_allowed and ( index == 0 ) )
                close_index = index
                close_match_text = match_text
                break
            end
        end

        return [ close_index, close_match_text ]
    end
    protected :findClosingMatch

    # @mark_start[ "col" ] is inclusive,
    # @mark_end[ "col" ] is exclusive.
    def recordMarkStartAndEnd
        if @mark_anchor != nil
            crow = @last_row
            ccol = @last_col
            anchor_first = true
            if crow < @mark_anchor[ "row" ]
                anchor_first = false
            elsif crow > @mark_anchor[ "row" ]
                anchor_first = true
            else
                if ccol < @mark_anchor[ "col" ]
                    anchor_first = false
                end
            end
            if anchor_first
                @text_marks[ SELECTION ] = TextMark.new(
                    @mark_anchor[ "row" ],
                    @mark_anchor[ "col" ],
                    crow,
                    ccol,
                    @selection_formatting
                )
            else
                @text_marks[ SELECTION ] = TextMark.new(
                    crow,
                    ccol,
                    @mark_anchor[ "row" ],
                    @mark_anchor[ "col" ],
                    @selection_formatting
                )
            end
        else
            @text_marks[ SELECTION ] = nil
        end
    end
    
    def selection_mark
      @text_marks[ SELECTION ]
    end
    def selecting?
      !!selection_mark
    end
    
    def select_current_line
      @text_marks[ SELECTION ] = TextMark.new(
        @last_row,
        0,
        @last_row,
        @lines[ @last_row ].size,
        @selection_formatting
      )
      @lines[ @last_row ]
    end
    
    def select_all
      anchorSelection( 0, 0, DONT_DISPLAY )
      cursorTo( @lines.length - 1, @lines[ -1 ].length, DO_DISPLAY )
    end
    
    def select( from_regexp, to_regexp, include_ending = true )
      start_row = nil
      
      @lines[ 0..@last_row ].reverse.each_with_index do |line,index|
        if line =~ from_regexp
          start_row = @last_row - index
          break
        end
      end
      if start_row
        end_row = nil
        @lines[ start_row..-1 ].each_with_index do |line,index|
          if line =~ to_regexp
            end_row = start_row + index
            break
          end
        end
        if end_row
          if include_ending
            end_row += 1
          end
          anchorSelection( start_row, 0, DONT_DISPLAY )
          cursorTo( end_row, 0 )
          display
        end
      end
    end

    # Prints text to the screen, truncating where necessary.
    # Returns nil if the string is completely off-screen.
    # write_cursor_col is buffer-relative, not screen-relative
    def truncateOffScreen( string, write_cursor_col )
        retval = string
        
        # Truncate based on left edge of display area
        if write_cursor_col < @left_column
            retval = retval[ (@left_column - write_cursor_col)..-1 ]
            write_cursor_col = @left_column
        end

        if retval != nil
            # Truncate based on right edge of display area
            if write_cursor_col + retval.length > @left_column + Curses::cols - 1
                new_length = ( @left_column + Curses::cols - write_cursor_col )
                if new_length <= 0
                    retval = nil
                else
                    retval = retval[ 0...new_length ]
                end
            end
        end
        
        return ( retval == "" ? nil : retval )
    end
    
    # For debugging purposes
    def quotedOrNil( str )
        if str == nil
            return "nil"
        else
            return "'#{str}'"
        end
    end
    
    def paintMarks( row )
        string = @lines[ row ][ @left_column ... @left_column + Curses::cols ]
        return if string == nil or string == ""
        string = string.expandTabs( @tab_size )
        cury = @win_main.cury
        curx = @win_main.curx
        
        @text_marks.reverse_each do |text_mark|
            if text_mark != nil
                @win_main.attrset text_mark.formatting
                if ( (text_mark.start_row + 1) .. (text_mark.end_row - 1) ) === row
                    @win_main.setpos( cury, curx )
                    @win_main.addstr string
                elsif row == text_mark.start_row and row == text_mark.end_row
                    expanded_col = tabExpandedColumn( text_mark.start_col, row )
                    if expanded_col < @left_column + Curses::cols
                        left = [ expanded_col - @left_column, 0 ].max
                        right = tabExpandedColumn( text_mark.end_col, row ) - @left_column
                        if left < right
                            @win_main.setpos( cury, curx + left )
                            @win_main.addstr string[ left...right ]
                        end
                    end
                elsif row == text_mark.start_row
                    expanded_col = tabExpandedColumn( text_mark.start_col, row )
                    if expanded_col < @left_column + Curses::cols
                        left = [ expanded_col - @left_column, 0 ].max
                        @win_main.setpos( cury, curx + left )
                        @win_main.addstr string[ left..-1 ]
                    end
                elsif row == text_mark.end_row
                    right = tabExpandedColumn( text_mark.end_col, row ) - @left_column
                    @win_main.setpos( cury, curx )
                    @win_main.addstr string[ 0...right ]
                else
                    # This row not in selection.
                end
            end
        end
    end

    def printString( string, formatting = ( @token_formats[ @continued_format_class ] or @default_formatting ) )
        return if not @pen_down
        return if string == nil

        @win_main.attrset formatting
        @win_main.addstr string
    end

    # This method assumes that the cursor has been setup already at
    # the left-most column of the correct on-screen row.
    # It merely unintelligently prints the characters on the current curses line,
    # refusing to print characters of the in-buffer line which are offscreen.
    def printLine( line )
        i = 0
        substr = nil
        index = nil
        while i < line.length
            substr = line[ i..-1 ]
            if @continued_format_class != nil
                close_index, close_match_text = findClosingMatch( substr, @close_token_regexps[ @continued_format_class ], i == 0 )

                if close_match_text == nil
                    printString truncateOffScreen( substr, i )
                    printPaddingFrom( line.length )
                    i = line.length
                else
                    end_index = close_index + close_match_text.length
                    printString truncateOffScreen( substr[ 0...end_index ], i )
                    @continued_format_class = nil
                    i += end_index
                end
            else
                first_index, first_token_class, first_word = findOpeningMatch( substr, MATCH_ANY, i == 0 )

                if @lang_stack.length > 0
                    prev_lang, close_token_class = @lang_stack[ -1 ]
                    close_index, close_match_text = findClosingMatch( substr, @diakonos.close_token_regexps[ prev_lang ][ close_token_class ], i == 0 )
                    if close_match_text != nil and close_index <= first_index
                        if close_index > 0
                            # Print any remaining text in the embedded language
                            printString truncateOffScreen( substr[ 0...close_index ], i )
                            i += substr[ 0...close_index ].length
                        end

                        @lang_stack.pop
                        setLanguage prev_lang

                        printString(
                            truncateOffScreen( substr[ close_index...(close_index + close_match_text.length) ], i ),
                            @token_formats[ close_token_class ]
                        )
                        i += close_match_text.length

                        # Continue printing from here.
                        next
                    end
                end

                if first_word != nil
                    if first_index > 0
                        # Print any preceding text in the default format
                        printString truncateOffScreen( substr[ 0...first_index ], i )
                        i += substr[ 0...first_index ].length
                    end
                    printString( truncateOffScreen( first_word, i ), @token_formats[ first_token_class ] )
                    i += first_word.length
                    if @close_token_regexps[ first_token_class ] != nil
                        if change_to = @settings[ "lang.#{@language}.tokens.#{first_token_class}.change_to" ]
                            @lang_stack.push [ @language, first_token_class ]
                            setLanguage change_to
                        else
                            @continued_format_class = first_token_class
                        end
                    end
                else
                    printString truncateOffScreen( substr, i )
                    i += substr.length
                    break
                end
            end
        end

        printPaddingFrom i
    end

    def printPaddingFrom( col )
        return if not @pen_down

        if col < @left_column
            remainder = Curses::cols
        else
            remainder = @left_column + Curses::cols - col
        end
        
        if remainder > 0
            printString( " " * remainder )
        end
    end

    def save( filename = nil, prompt_overwrite = DONT_PROMPT_OVERWRITE )
        if filename != nil
            name = filename.subHome
        else
            name = @name
        end
        
        if @read_only and FileTest.exists?( @name ) and FileTest.exists?( name ) and ( File.stat( @name ).ino == File.stat( name ).ino )
            @diakonos.setILine "#{name} cannot be saved since it is read-only."
        else
            @name = name
            @read_only = false
            if @name == nil
                @diakonos.saveFileAs
            #elsif name.empty?
                #@diakonos.setILine "(file not saved)"
                #@name = nil
            else
                proceed = true
                
                if prompt_overwrite and FileTest.exists? @name
                    proceed = false
                    choice = @diakonos.getChoice(
                        "Overwrite existing '#{@name}'?",
                        [ CHOICE_YES, CHOICE_NO ],
                        CHOICE_NO
                    )
                    case choice
                        when CHOICE_YES
                            proceed = true
                        when CHOICE_NO
                            proceed = false
                    end
                end
                
                if file_modified
                    proceed = ! @diakonos.revert( "File has been altered externally.  Load on-disk version?" )
                end
                
                if proceed
                    File.open( @name, "w" ) do |f|
                        @lines[ 0..-2 ].each do |line|
                            f.puts line
                        end
                        if @lines[ -1 ] != ""
                            # No final newline character
                            f.print @lines[ -1 ]
                            f.print "\n" if @settings[ "eof_newline" ]
                        end
                    end
                    @last_modification_check = File.mtime( @name )
                        
                    if @name == @diakonos.diakonos_conf
                        @diakonos.loadConfiguration
                        @diakonos.initializeDisplay
                    end
                    
                    @modified = false
                    
                    display
                    @diakonos.updateStatusLine
                end
            end
        end
    end

    # Returns true on successful write.
    def saveCopy( filename )
        return false if filename.nil?
        
        name = filename.subHome
        
        File.open( name, "w" ) do |f|
            @lines[ 0..-2 ].each do |line|
                f.puts line
            end
            if @lines[ -1 ] != ""
                # No final newline character
                f.print @lines[ -1 ]
                f.print "\n" if @settings[ "eof_newline" ]
            end
        end
        
        return true
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

    # x and y are given window-relative, not buffer-relative.
    def delete
        if selection_mark != nil
            deleteSelection
        else
            row = @last_row
            col = @last_col
            if ( row >= 0 ) and ( col >= 0 )
                line = @lines[ row ]
                if col == line.length
                    if row < @lines.length - 1
                        # Delete newline, and concat next line
                        joinLines( row )
                        cursorTo( @last_row, @last_col )
                    end
                else
                    takeSnapshot( TYPING )
                    @lines[ row ] = line[ 0...col ] + line[ (col + 1)..-1 ]
                    setModified
                end
            end
        end
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
        else
          @diakonos.log h[ :regexp ].inspect + " does not match '#{line}'"
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
    
    def comment_out
      takeSnapshot
      selection = selection_mark
      if selection
        if selection.end_col == 0
          end_row = selection.end_row - 1
        else
          end_row = selection.end_row
        end
        lines = @lines[ selection.start_row..end_row ]
      else
        lines = [ @lines[ @last_row ] ]
      end
      one_modified = false
      lines.each do |line|
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
      selection = selection_mark
      if selection
        if selection.end_col == 0
          end_row = selection.end_row - 1
        else
          end_row = selection.end_row
        end
        lines = @lines[ selection.start_row..end_row ]
      else
        lines = [ @lines[ @last_row ] ]
      end
      comment_string = Regexp.escape( @settings[ "lang.#{@language}.comment_string" ].to_s )
      comment_close_string = Regexp.escape( @settings[ "lang.#{@language}.comment_close_string" ].to_s )
      one_modified = false
      lines.each do |line|
        old_line = line.dup
        line.gsub!( /^(\s*)#{comment_string}/, "\\1" )
        line.gsub!( /#{comment_close_string}$/, '' )
        one_modified ||= ( line != old_line )
      end
      if one_modified
        setModified
      end
    end

    def deleteLine
        removeSelection( DONT_DISPLAY ) if selection_mark != nil

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
        cursorTo( row, 0 )
        setModified

        retval
    end

    def deleteToEOL
        removeSelection( DONT_DISPLAY ) if selection_mark != nil

        row = @last_row
        col = @last_col
        
        takeSnapshot
        if @settings[ 'delete_newline_on_delete_to_eol' ] and col == @lines[ row ].size
          next_line = @lines.delete_at( row + 1 )
          @lines[ row ] << next_line
          retval = ''
        else        
          retval = [ @lines[ row ][ col..-1 ] ]
          @lines[ row ] = @lines[ row ][ 0...col ]
        end
        setModified

        retval
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
        return ( x + @left_column < lineAt( y ).length )
    end

    # Translates the window column, x, to a buffer-relative column index.
    def columnOf( x )
        return @left_column + x
    end

    # Translates the window row, y, to a buffer-relative row index.
    def rowOf( y )
        return @top_line + y
    end
    
    # Returns nil if the row is off-screen.
    def rowToY( row )
        return nil if row == nil
        y = row - @top_line
        y = nil if ( y < 0 ) or ( y > @top_line + @diakonos.main_window_height - 1 )
        return y
    end
    
    # Returns nil if the column is off-screen.
    def columnToX( col )
        return nil if col == nil
        x = col - @left_column
        x = nil if ( x < 0 ) or ( x > @left_column + Curses::cols - 1 )
        return x
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
        return ( @left_column - old_left_column )
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
            highlightMatches
            if @diakonos.there_was_non_movement
                pushCursorState( old_top_line, old_row, old_col )
            end
        end

        display if do_display

        return changed
    end
    
    def pushCursorState( top_line, row, col, clear_stack_pointer = CLEAR_STACK_POINTER )
        new_state = {
            :top_line => top_line,
            :row => row,
            :col => col
        }
        if not @cursor_stack.include? new_state
            @cursor_stack << new_state
            if clear_stack_pointer
                @cursor_stack_pointer = nil
            end
            @diakonos.clearNonMovementFlag
        end
    end

    # Returns true iff the cursor changed positions in the buffer.
    def cursorTo( row, col, do_display = DONT_DISPLAY, stopped_typing = STOPPED_TYPING, adjust_row = ADJUST_ROW )
        old_last_row = @last_row
        old_last_col = @last_col
        
        row = row.fit( 0, @lines.length - 1 )

        if col < 0
            if adjust_row
                if row > 0
                    row = row - 1
                    col = @lines[ row ].length
                else
                    col = 0
                end
            else
                col = 0
            end
        elsif col > @lines[ row ].length
            if adjust_row
                if row < @lines.length - 1
                    row = row + 1
                    col = 0
                else
                    col = @lines[ row ].length
                end
            else
                col = @lines[ row ].length
            end
        end

        if adjust_row
            @desired_column = col
        else
            goto_col = [ @desired_column, @lines[ row ].length ].min
            if col < goto_col
                col = goto_col
            end
        end

        new_col = tabExpandedColumn( col, row )
        view_changed = showCharacter( row, new_col )
        @last_screen_y = row - @top_line
        @last_screen_x = new_col - @left_column
        
        @typing = false if stopped_typing
        @last_row = row
        @last_col = col
        @last_screen_col = new_col
        changed = ( @last_row != old_last_row or @last_col != old_last_col )
        if changed
            recordMarkStartAndEnd
            
            removed = false
            if not @changing_selection and selection_mark != nil
                removeSelection( DONT_DISPLAY )
                removed = true
            end
            if removed or ( do_display and ( selection_mark != nil or view_changed ) )
                display
            else
                @diakonos.display_mutex.synchronize do
                    @win_main.setpos( @last_screen_y, @last_screen_x )
                end
            end
            @diakonos.updateStatusLine
            @diakonos.updateContextLine
        end
        
        return changed
    end
    
    def cursorReturn( direction )
        delta = 0
        if @cursor_stack_pointer.nil?
            pushCursorState( @top_line, @last_row, @last_col, DONT_CLEAR_STACK_POINTER )
            delta = 1
        end
        case direction
            when :forward
                @cursor_stack_pointer = ( @cursor_stack_pointer || 0 ) + 1
            #when :backward
            else
                @cursor_stack_pointer = ( @cursor_stack_pointer || @cursor_stack.length ) - 1 - delta
        end
        
        return_pointer = @cursor_stack_pointer
        
        if @cursor_stack_pointer < 0
            return_pointer = @cursor_stack_pointer = 0
        elsif @cursor_stack_pointer >= @cursor_stack.length
            return_pointer = @cursor_stack_pointer = @cursor_stack.length - 1
        else
            cursor_state = @cursor_stack[ @cursor_stack_pointer ]
            if cursor_state != nil
                pitchView( cursor_state[ :top_line ] - @top_line, DONT_PITCH_CURSOR, DO_DISPLAY )
                cursorTo( cursor_state[ :row ], cursor_state[ :col ] )
                @diakonos.updateStatusLine
            end
        end
        
        return return_pointer, @cursor_stack.size
    end
    
    def tabExpandedColumn( col, row )
        delta = 0
        line = @lines[ row ]
        for i in 0...col
            if line[ i ] == TAB
                delta += ( @tab_size - ( (i+delta) % @tab_size ) ) - 1
            end
        end
        return ( col + delta )
    end

    def cursorToEOF
        cursorTo( @lines.length - 1, @lines[ -1 ].length, DO_DISPLAY )
    end

    def cursorToBOL
        row = @last_row
        case @settings[ "bol_behaviour" ]
            when BOL_ZERO
                col = 0
            when BOL_FIRST_CHAR
                col = ( ( @lines[ row ] =~ /\S/ ) or 0 )
            when BOL_ALT_ZERO
                if @last_col == 0
                    col = ( @lines[ row ] =~ /\S/ )
                else
                    col = 0
                end
            #when BOL_ALT_FIRST_CHAR
            else
                first_char_col = ( ( @lines[ row ] =~ /\S/ ) or 0 )
                if @last_col == first_char_col
                    col = 0
                else
                    col = first_char_col
                end
        end
        cursorTo( row, col, DO_DISPLAY )
    end
    
    def cursorToEOL
      y = @win_main.cury
      end_col = lineAt( y ).length
      last_char_col = lineAt( y ).rstrip.length
      case @settings[ 'eol_behaviour' ]
      when EOL_END
        col = end_col
      when EOL_LAST_CHAR
        col = last_char_col
      when EOL_ALT_LAST_CHAR
        if @last_col == last_char_col
          col = end_col
        else
          col = last_char_col
        end
      else
        if @last_col == end_col
          col = last_char_col
        else
          col = end_col
        end
      end
      cursorTo( @last_row, col, DO_DISPLAY )
    end

    # Top of view
    def cursorToTOV
        cursorTo( rowOf( 0 ), @last_col, DO_DISPLAY )
    end
    # Bottom of view
    def cursorToBOV
        cursorTo( rowOf( 0 + @diakonos.main_window_height - 1 ), @last_col, DO_DISPLAY )
    end

    # col and row are given relative to the buffer, not any window or screen.
    # Returns true if the view changed positions.
    def showCharacter( row, col )
        old_top_line = @top_line
        old_left_column = @left_column

        while row < @top_line + @settings[ "view.margin.y" ]
            amount = (-1) * @settings[ "view.jump.y" ]
            break if( pitchView( amount, DONT_PITCH_CURSOR, DONT_DISPLAY ) != amount )
        end
        while row > @top_line + @diakonos.main_window_height - 1 - @settings[ "view.margin.y" ]
            amount = @settings[ "view.jump.y" ]
            break if( pitchView( amount, DONT_PITCH_CURSOR, DONT_DISPLAY ) != amount )
        end

        while col < @left_column + @settings[ "view.margin.x" ]
            amount = (-1) * @settings[ "view.jump.x" ]
            break if( panView( amount, DONT_DISPLAY ) != amount )
        end
        while col > @left_column + @diakonos.main_window_width - @settings[ "view.margin.x" ] - 2
            amount = @settings[ "view.jump.x" ]
            break if( panView( amount, DONT_DISPLAY ) != amount )
        end

        return ( @top_line != old_top_line or @left_column != old_left_column )
    end

    def setIndent( row, level, do_display = DO_DISPLAY )
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

        takeSnapshot( TYPING ) if do_display
        @lines[ row ] = indent_text + rest
        cursorTo( row, indentation ) if do_display
        setModified
    end

    def parsedIndent( row = @last_row, do_display = DO_DISPLAY )
        if row == 0
            level = 0
        else
            # Look upwards for the nearest line on which to base this line's indentation.
            i = 1
            while ( @lines[ row - i ] =~ /^[\s#{@indent_ignore_charset}]*$/ ) or
                  ( @lines[ row - i ] =~ @settings[ "lang.#{@language}.indent.ignore" ] )
                i += 1
            end
            if row - i < 0
                level = 0
            else
                prev_line = @lines[ row - i ]
                level = prev_line.indentation_level( @indent_size, @indent_roundup, @tab_size, @indent_ignore_charset )

                line = @lines[ row ]
                if @preventers != nil
                    prev_line = prev_line.gsub( @preventers, "" )
                    line = line.gsub( @preventers, "" )
                end

                indenter_index = ( prev_line =~ @indenters )
                if indenter_index
                    level += 1
                    unindenter_index = (prev_line =~ @unindenters)
                    if unindenter_index and unindenter_index != indenter_index
                        level += -1
                    end
                end
                if line =~ @unindenters
                    level += -1
                end
            end
        end

        setIndent( row, level, do_display )

    end

    def indent( row = @last_row, do_display = DO_DISPLAY )
        level = @lines[ row ].indentation_level( @indent_size, @indent_roundup, @tab_size )
        setIndent( row, level + 1, do_display )
    end

    def unindent( row = @last_row, do_display = DO_DISPLAY )
        level = @lines[ row ].indentation_level( @indent_size, @indent_roundup, @tab_size )
        setIndent( row, level - 1, do_display )
    end

    def anchorSelection( row = @last_row, col = @last_col, do_display = DO_DISPLAY )
        @mark_anchor = ( @mark_anchor or Hash.new )
        @mark_anchor[ "row" ] = row
        @mark_anchor[ "col" ] = col
        recordMarkStartAndEnd
        @changing_selection = true
        display if do_display
    end

    def removeSelection( do_display = DO_DISPLAY )
        return if selection_mark.nil?
        @mark_anchor = nil
        recordMarkStartAndEnd
        @changing_selection = false
        @last_finding = nil
        display if do_display
    end
    
    def toggleSelection
        if @changing_selection
            removeSelection
        else
            anchorSelection
        end
    end

    def copySelection
      selected_text
    end
    def selected_text
      selection = selection_mark
      if selection.nil?
        nil
      elsif selection.start_row == selection.end_row
        [ @lines[ selection.start_row ][ selection.start_col...selection.end_col ] ]
      else
        [ @lines[ selection.start_row ][ selection.start_col..-1 ] ] +
          ( @lines[ (selection.start_row + 1) .. (selection.end_row - 1) ] or [] ) +
          [ @lines[ selection.end_row ][ 0...selection.end_col ] ]
      end
    end
    def selected_string
      lines = selected_text
      if lines
        lines.join( "\n" )
      else
        nil
      end
    end

    def deleteSelection( do_display = DO_DISPLAY )
        return if @text_marks[ SELECTION ] == nil

        takeSnapshot

        selection = @text_marks[ SELECTION ]
        start_row = selection.start_row
        start_col = selection.start_col
        start_line = @lines[ start_row ]

        if selection.end_row == selection.start_row
            @lines[ start_row ] = start_line[ 0...start_col ] + start_line[ selection.end_col..-1 ]
        else
            end_line = @lines[ selection.end_row ]
            @lines[ start_row ] = start_line[ 0...start_col ] + end_line[ selection.end_col..-1 ]
            @lines = @lines[ 0..start_row ] + @lines[ (selection.end_row + 1)..-1 ]
        end

        cursorTo( start_row, start_col )
        removeSelection( DONT_DISPLAY )
        setModified( do_display )
    end

    # text is an array of Strings, or a String with zero or more newlines ("\n")
    def paste( text, do_parsed_indent = false )
      return if text == nil
      
      if not text.kind_of? Array
        s = text.to_s
        if s.include?( "\n" )
          text = s.split( "\n", -1 )
        else
          text = [ s ]
        end
      end
      
      takeSnapshot
      
      deleteSelection( DONT_DISPLAY )
      
      row = @last_row
      col = @last_col
      line = @lines[ row ]
      if text.length == 1
        @lines[ row ] = line[ 0...col ] + text[ 0 ] + line[ col..-1 ]
        if do_parsed_indent
          parsedIndent row, DONT_DISPLAY
        end
        cursorTo( @last_row, @last_col + text[ 0 ].length )
      elsif text.length > 1
        @lines[ row ] = line[ 0...col ] + text[ 0 ]
        @lines[ row + 1, 0 ] = text[ -1 ] + line[ col..-1 ]
        @lines[ row + 1, 0 ] = text[ 1..-2 ]
        new_row = @last_row + text.length - 1
        if do_parsed_indent
          ( row..new_row ).each do |r|
            parsedIndent r, DONT_DISPLAY
          end
        end
        cursorTo( new_row, columnOf( text[ -1 ].length ) )
      end
      
      setModified
    end

    # Takes an array of Regexps, which represents a user-provided regexp,
    # split across newline characters.  Once the first element is found,
    # each successive element must match against lines following the first
    # element.
    def find( regexps, options = {} )
        return if regexps.nil?
        regexp = regexps[ 0 ]
        return if regexp == nil or regexp == //
        
        direction = options[ :direction ]
        replacement = options[ :replacement ]
        auto_choice = options[ :auto_choice ]
        from_row = options[ :starting_row ] || @last_row
        from_col = options[ :starting_col ] || @last_col
        
        if direction == :opposite
            case @last_search_direction
                when :up
                    direction = :down
                else
                    direction = :up
            end
        end
        @last_search_regexps = regexps
        @last_search_direction = direction
        
        finding = nil
        wrapped = false
        match = nil
        
        catch :found do
        
            if direction == :down
                # Check the current row first.
                
                if index = @lines[ from_row ].index( regexp, ( @last_finding ? @last_finding.start_col : from_col ) + 1 )
                  match = Regexp.last_match
                  found_text = match[ 0 ]
                  finding = Finding.new( from_row, index, from_row, index + found_text.length )
                  if finding.match( regexps, @lines )
                    throw :found
                  else
                    finding = nil
                  end
                end
                
                # Check below the cursor.
                
                ( (from_row + 1)...@lines.length ).each do |i|
                    if index = @lines[ i ].index( regexp )
                      match = Regexp.last_match
                      found_text = match[ 0 ]
                      finding = Finding.new( i, index, i, index + found_text.length )
                      if finding.match( regexps, @lines )
                        throw :found
                      else
                        finding = nil
                      end
                    end
                end
                
                # Wrap around.
                
                wrapped = true
                
                ( 0...from_row ).each do |i|
                    if index = @lines[ i ].index( regexp )
                      match = Regexp.last_match
                      found_text = match[ 0 ]
                      finding = Finding.new( i, index, i, index + found_text.length )
                      if finding.match( regexps, @lines )
                        throw :found
                      else
                        finding = nil
                      end
                    end
                end
                
                # And finally, the other side of the current row.
                
                #if index = @lines[ from_row ].index( regexp, ( @last_finding ? @last_finding.start_col : from_col ) - 1 )
                if index = @lines[ from_row ].index( regexp )
                    if index <= ( @last_finding ? @last_finding.start_col : from_col )
                      match = Regexp.last_match
                      found_text = match[ 0 ]
                      finding = Finding.new( from_row, index, from_row, index + found_text.length )
                      if finding.match( regexps, @lines )
                        throw :found
                      else
                        finding = nil
                      end
                    end
                end
                
            elsif direction == :up
                # Check the current row first.
                
                col_to_check = ( @last_finding ? @last_finding.end_col : from_col ) - 1
                if ( col_to_check >= 0 ) and ( index = @lines[ from_row ][ 0...col_to_check ].rindex( regexp ) )
                  match = Regexp.last_match
                  found_text = match[ 0 ]
                  finding = Finding.new( from_row, index, from_row, index + found_text.length )
                  if finding.match( regexps, @lines )
                    throw :found
                  else
                    finding = nil
                  end
                end
                
                # Check above the cursor.
                
                (from_row - 1).downto( 0 ) do |i|
                    if index = @lines[ i ].rindex( regexp )
                      match = Regexp.last_match
                      found_text = match[ 0 ]
                      finding = Finding.new( i, index, i, index + found_text.length )
                      if finding.match( regexps, @lines )
                        throw :found
                      else
                        finding = nil
                      end
                    end
                end
                
                # Wrap around.
                
                wrapped = true
                
                (@lines.length - 1).downto(from_row + 1) do |i|
                    if index = @lines[ i ].rindex( regexp )
                      match = Regexp.last_match
                      found_text = match[ 0 ]
                      finding = Finding.new( i, index, i, index + found_text.length )
                      if finding.match( regexps, @lines )
                        throw :found
                      else
                        finding = nil
                      end
                    end
                end
                
                # And finally, the other side of the current row.
                
                search_col = ( @last_finding ? @last_finding.start_col : from_col ) + 1
                if index = @lines[ from_row ].rindex( regexp )
                    if index > search_col
                      match = Regexp.last_match
                      found_text = match[ 0 ]
                      finding = Finding.new( from_row, index, from_row, index + found_text.length )
                      if finding.match( regexps, @lines )
                        throw :found
                      else
                        finding = nil
                      end
                    end
                end
            end
        end
        
        if finding
            if wrapped and not options[ :quiet ]
              @diakonos.setILine( "(search wrapped around BOF/EOF)" )
            end
            
            removeSelection( DONT_DISPLAY )
            @last_finding = finding
            if @settings[ "found_cursor_start" ]
                anchorSelection( finding.end_row, finding.end_col, DONT_DISPLAY )
                cursorTo( finding.start_row, finding.start_col )
            else
                anchorSelection( finding.start_row, finding.start_col, DONT_DISPLAY )
                cursorTo( finding.end_row, finding.end_col )
            end

            @changing_selection = false
            
            if regexps.length == 1
                @highlight_regexp = regexp
                highlightMatches
            else
                clearMatches
            end
            display
            
            if replacement
              # Substitute placeholders (e.g. \1) in str for the group matches of the last match.
              actual_replacement = replacement.dup
              actual_replacement.gsub!( /\\(\\|\d+)/ ) { |m|
                ref = $1
                if ref == "\\"
                  "\\"
                else
                  match[ ref.to_i ]
                end
              }
              
              choice = auto_choice || @diakonos.getChoice(
                "Replace?",
                [ CHOICE_YES, CHOICE_NO, CHOICE_ALL, CHOICE_CANCEL, CHOICE_YES_AND_STOP ],
                CHOICE_YES
              )
              case choice
              when CHOICE_YES
                paste [ actual_replacement ]
                find( regexps, :direction => direction, :replacement => replacement )
              when CHOICE_ALL
                replaceAll( regexp, replacement )
              when CHOICE_NO
                find( regexps, :direction => direction, :replacement => replacement )
              when CHOICE_CANCEL
                # Do nothing further.
              when CHOICE_YES_AND_STOP
                paste [ actual_replacement ]
                # Do nothing further.
              end
            end
        else
          removeSelection DONT_DISPLAY
          clearMatches DO_DISPLAY
          if not options[ :quiet ]
            @diakonos.setILine "/#{regexp.source}/ not found."
          end
        end
    end

    def replaceAll( regexp, replacement )
        return if( regexp == nil or replacement == nil )

        @lines = @lines.collect { |line|
            line.gsub( regexp, replacement )
        }
        setModified

        clearMatches

        display
    end
    
    def highlightMatches
        if @highlight_regexp != nil
            found_marks = @lines[ @top_line...(@top_line + @diakonos.main_window_height) ].grep_indices( @highlight_regexp ).collect do |line_index, start_col, end_col|
                TextMark.new( @top_line + line_index, start_col, @top_line + line_index, end_col, @settings[ "lang.#{@language}.format.found" ] )
            end
            #@text_marks = [ nil ] + found_marks
            @text_marks = [ @text_marks[ 0 ] ] + found_marks
        end
    end

    def clearMatches( do_display = DONT_DISPLAY )
        selection = @text_marks[ SELECTION ]
        @text_marks = Array.new
        @text_marks[ SELECTION ] = selection
        @highlight_regexp = nil
        display if do_display
    end

    def findAgain( last_search_regexps, direction = @last_search_direction )
        if @last_search_regexps.nil?
          @last_search_regexps = last_search_regexps
        end
        if @last_search_regexps
          find( @last_search_regexps, :direction => direction )
        end
    end
    
    def seek( regexp, direction = :down )
        return if regexp == nil or regexp == //
        
        found_row = nil
        found_col = nil
        found_text = nil
        wrapped = false
        
        catch :found do
            if direction == :down
                # Check the current row first.
                
                index, match_text = @lines[ @last_row ].group_index( regexp, @last_col + 1 )
                if index != nil
                    found_row = @last_row
                    found_col = index
                    found_text = match_text
                    throw :found
                end
                
                # Check below the cursor.
                
                ( (@last_row + 1)...@lines.length ).each do |i|
                    index, match_text = @lines[ i ].group_index( regexp )
                    if index != nil
                        found_row = i
                        found_col = index
                        found_text = match_text
                        throw :found
                    end
                end
                
            else
                # Check the current row first.
                
                #col_to_check = ( @last_found_col or @last_col ) - 1
                col_to_check = @last_col - 1
                if col_to_check >= 0
                    index, match_text = @lines[ @last_row ].group_rindex( regexp, col_to_check )
                    if index != nil
                        found_row = @last_row
                        found_col = index
                        found_text = match_text
                        throw :found
                    end
                end
                
                # Check above the cursor.
                
                (@last_row - 1).downto( 0 ) do |i|
                    index, match_text = @lines[ i ].group_rindex( regexp )
                    if index != nil
                        found_row = i
                        found_col = index
                        found_text = match_text
                        throw :found
                    end
                end
            end
        end
        
        if found_text != nil
            #@last_found_row = found_row
            #@last_found_col = found_col
            cursorTo( found_row, found_col )
            
            display
        end
    end    

    def setModified( do_display = DO_DISPLAY )
        if @read_only
            @diakonos.setILine "Warning: Modifying a read-only file."
        end

        fmod = false
        if not @modified
            @modified = true
            fmod = file_modified
        end
        
        reverted = false
        if fmod
            reverted = @diakonos.revert( "File has been altered externally.  Load on-disk version?" )
        end
        
        if not reverted
            clearMatches
            if do_display
                @diakonos.updateStatusLine
                display
            end
        end
    end
    
    # Check if the file which is being edited has been modified since
    # the last time we checked it; return true if so, false otherwise.
    def file_modified
        modified = false
        
        if @name != nil
            begin
                mtime = File.mtime( @name )
                
                if mtime > @last_modification_check
                    modified = true
                    @last_modification_check = mtime
                end
            rescue Errno::ENOENT
                # Ignore if file doesn't exist
            end
        end
        
        return modified
    end

    def takeSnapshot( typing = false )
        take_snapshot = false
        if @typing != typing
            @typing = typing
            # If we just started typing, take a snapshot, but don't continue
            # taking snapshots for every keystroke
            if typing
                take_snapshot = true
            end
        end
        if not @typing
            take_snapshot = true
        end

        if take_snapshot
            undo_size = 0
            @buffer_states[ 1..-1 ].each do |state|
                undo_size += state.length
            end
            while ( ( undo_size + @lines.length ) >= @settings[ "max_undo_lines" ] ) and @buffer_states.length > 1
                @cursor_states.pop
                popped_state = @buffer_states.pop
                undo_size = undo_size - popped_state.length
            end
            if @current_buffer_state > 0
                @buffer_states.unshift @lines.deep_clone
                @cursor_states.unshift [ @last_row, @last_col ]
            end
            @buffer_states.unshift @lines.deep_clone
            @cursor_states.unshift [ @last_row, @last_col ]
            @current_buffer_state = 0
            @lines = @buffer_states[ @current_buffer_state ]
        end
    end

    def undo
      if @current_buffer_state < @buffer_states.length - 1
        @current_buffer_state += 1
        @lines = @buffer_states[ @current_buffer_state ]
        cursorTo( @cursor_states[ @current_buffer_state - 1 ][ 0 ], @cursor_states[ @current_buffer_state - 1 ][ 1 ] )
        @diakonos.setILine "Undo level: #{@current_buffer_state} of #{@buffer_states.length - 1}"
        setModified
      end
    end

    # Since redo is a Ruby keyword...
    def unundo
      if @current_buffer_state > 0
        @current_buffer_state += -1
        @lines = @buffer_states[ @current_buffer_state ]
        cursorTo( @cursor_states[ @current_buffer_state ][ 0 ], @cursor_states[ @current_buffer_state ][ 1 ] )
        @diakonos.setILine "Undo level: #{@current_buffer_state} of #{@buffer_states.length - 1}"
        setModified
      end
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

    def goToLine( line = nil, column = nil )
      cursorTo( line || @last_row, column || 0, DO_DISPLAY )
    end

    def goToNextBookmark
      cur_pos = Bookmark.new( self, @last_row, @last_col )
      next_bm = @bookmarks.find do |bm|
        bm > cur_pos
      end
      if next_bm
        cursorTo( next_bm.row, next_bm.col, DO_DISPLAY )
      end
    end

    def goToPreviousBookmark
        cur_pos = Bookmark.new( self, @last_row, @last_col )
        # There's no reverse_find method, so, we have to do this manually.
        prev = nil
        @bookmarks.reverse_each do |bm|
            if bm < cur_pos
                prev = bm
                break
            end
        end
        if prev != nil
            cursorTo( prev.row, prev.col, DO_DISPLAY )
        end
    end

    def toggleBookmark
        bookmark = Bookmark.new( self, @last_row, @last_col )
        existing = @bookmarks.find do |bm|
            bm == bookmark
        end
        if existing
            @bookmarks.delete existing
            @diakonos.setILine "Bookmark #{existing.to_s} deleted."
        else
            @bookmarks.push bookmark
            @bookmarks.sort
            @diakonos.setILine "Bookmark #{bookmark.to_s} set."
        end
    end

    def context
        retval = Array.new
        row = @last_row
        clevel = @lines[ row ].indentation_level( @indent_size, @indent_roundup, @tab_size, @indent_ignore_charset )
        while row > 0 and clevel < 0
            row = row - 1
            clevel = @lines[ row ].indentation_level( @indent_size, @indent_roundup, @tab_size, @indent_ignore_charset )
        end
        clevel = 0 if clevel < 0
        while row > 0
            row = row - 1
            line = @lines[ row ]
            if line !~ @settings[ "lang.#{@language}.context.ignore" ]
                level = line.indentation_level( @indent_size, @indent_roundup, @tab_size, @indent_ignore_charset )
                if level < clevel and level > -1
                    retval.unshift line
                    clevel = level
                    break if clevel == 0
                end
            end
        end
        return retval
    end

    def setType( type )
        success = false
        if type != nil
            configure( type )
            display
            success = true
        end
        return success
    end
    
    def wordUnderCursor
        word = nil
        
        @lines[ @last_row ].scan( /\w+/ ) do |match_text|
            last_match = Regexp.last_match
            if last_match.begin( 0 ) <= @last_col and @last_col < last_match.end( 0 )
                word = match_text
                break
            end
        end
        
        return word
    end
end

end