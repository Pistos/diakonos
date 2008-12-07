module Diakonos
  module Functions
    def addNamedBookmark( name_ = nil )
      if name_.nil?
        name = getUserInput "Bookmark name: "
      else
        name = name_
      end

      if name
        @bookmarks[ name ] = Bookmark.new( @current_buffer, @current_buffer.currentRow, @current_buffer.currentColumn, name )
        setILine "Added bookmark #{@bookmarks[ name ].to_s}."
      end
    end

    def anchorSelection
      @current_buffer.anchorSelection
      updateStatusLine
    end

    def backspace
      delete if( @current_buffer.changing_selection or cursorLeft( Buffer::STILL_TYPING ) )
    end

    def carriageReturn
      @current_buffer.carriageReturn
      @current_buffer.deleteSelection
    end

    def changeSessionSetting( key_ = nil, value = nil, do_redraw = DONT_REDRAW )
        if key_.nil?
            key = getUserInput( "Setting: " )
        else
            key = key_
        end

        if key
            if value.nil?
                value = getUserInput( "Value: " )
            end
            case @settings[ key ]
                when String
                    value = value.to_s
                when Fixnum
                    value = value.to_i
                when TrueClass, FalseClass
                    value = value.to_b
            end
            @session[ 'settings' ][ key ] = value
            redraw if do_redraw
            setILine "#{key} = #{value}"
        end
    end

    def clearMatches
        @current_buffer.clearMatches Buffer::DO_DISPLAY
    end

    def close_code
        @current_buffer.close_code
    end

    # Returns the choice the user made, or nil if the user was not prompted to choose.
    def closeFile( buffer = @current_buffer, to_all = nil )
        return nil if buffer.nil?

        choice = nil
        if @buffers.has_value?( buffer )
            do_closure = true

            if buffer.modified?
                if not buffer.read_only
                    if to_all.nil?
                        choices = [ CHOICE_YES, CHOICE_NO, CHOICE_CANCEL ]
                        if @quitting
                            choices.concat [ CHOICE_YES_TO_ALL, CHOICE_NO_TO_ALL ]
                        end
                        choice = getChoice(
                            "Save changes to #{buffer.nice_name}?",
                            choices,
                            CHOICE_CANCEL
                        )
                    else
                        choice = to_all
                    end
                    case choice
                        when CHOICE_YES, CHOICE_YES_TO_ALL
                            do_closure = true
                            saveFile( buffer )
                        when CHOICE_NO, CHOICE_NO_TO_ALL
                            do_closure = true
                        when CHOICE_CANCEL
                            do_closure = false
                    end
                end
            end

            if do_closure
                del_buffer_key = nil
                previous_buffer = nil
                to_switch_to = nil
                switching = false

                # Search the buffer hash for the buffer we want to delete,
                # and mark the one we will switch to after deletion.
                @buffers.each do |buffer_key,buf|
                    if switching
                        to_switch_to = buf
                        break
                    end
                    if buf == buffer
                        del_buffer_key = buffer_key
                        switching = true
                        next
                    end
                    previous_buffer = buf
                end

                buf = nil
                while(
                    ( not @buffer_stack.empty? ) and
                    ( not @buffers.values.include?( buf ) ) or
                    ( @buffers.index( buf ) == del_buffer_key )
                ) do
                    buf = @buffer_stack.pop
                end
                if @buffers.values.include?( buf )
                    to_switch_to = buf
                end

                if to_switch_to
                    switchTo( to_switch_to )
                elsif previous_buffer
                    switchTo( previous_buffer )
                else
                    # No buffers left.  Open a new blank one.
                    openFile
                end

                @buffers.delete del_buffer_key
                save_session

                updateStatusLine
                updateContextLine
            end
        else
            log "No such buffer: #{buffer.name}"
        end

        choice
    end

    def collapseWhitespace
      @current_buffer.collapseWhitespace
    end

    def columnize( delimiter = nil, num_spaces_padding = 0 )
      if delimiter.nil?
        delimiter = getUserInput(
          "Column delimiter (regexp): ",
          @rlh_general,
          @settings[ "lang.#{@current_buffer.original_language}.column_delimiters" ] || ''
        )
      end
      if delimiter and num_spaces_padding
        @current_buffer.columnize Regexp.new( delimiter ), num_spaces_padding
      end
    end

    def comment_out
      @current_buffer.comment_out
    end

    def copySelection
      @clipboard.addClip @current_buffer.copySelection
      removeSelection
    end

    def copy_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        removeSelection
      end
    end

    # Returns true iff the cursor changed positions
    def cursorDown
        @current_buffer.cursorTo( @current_buffer.last_row + 1, @current_buffer.last_col, Buffer::DO_DISPLAY, Buffer::STOPPED_TYPING, DONT_ADJUST_ROW )
    end

    # Returns true iff the cursor changed positions
    def cursorLeft( stopped_typing = Buffer::STOPPED_TYPING )
        @current_buffer.cursorTo( @current_buffer.last_row, @current_buffer.last_col - 1, Buffer::DO_DISPLAY, stopped_typing )
    end

    def cursorRight( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
        @current_buffer.cursorTo( @current_buffer.last_row, @current_buffer.last_col + amount, Buffer::DO_DISPLAY, stopped_typing )
    end

    # Returns true iff the cursor changed positions
    def cursorUp
        @current_buffer.cursorTo( @current_buffer.last_row - 1, @current_buffer.last_col, Buffer::DO_DISPLAY, Buffer::STOPPED_TYPING, DONT_ADJUST_ROW )
    end

    def cursorBOF
        @current_buffer.cursorTo( 0, 0, Buffer::DO_DISPLAY )
    end

    def cursorBOL
        @current_buffer.cursorToBOL
    end

    def cursorEOL
      @current_buffer.cursorToEOL
    end

    def cursorEOF
        @current_buffer.cursorToEOF
    end

    # Top of view
    def cursorTOV
        @current_buffer.cursorToTOV
    end

    # Bottom of view
    def cursorBOV
        @current_buffer.cursorToBOV
    end

    def cursorReturn( dir_str = "backward" )
        stack_pointer, stack_size = @current_buffer.cursorReturn( dir_str.toDirection( :backward ) )
        setILine( "Location: #{stack_pointer+1}/#{stack_size}" )
    end

    def cutSelection
        delete if @clipboard.addClip( @current_buffer.copySelection )
    end

    def cut_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        delete
      end
    end

    def delete
        @current_buffer.delete
    end

    def delete_and_store_line_to_klipper
      removed_text = @current_buffer.deleteLine
      if removed_text
        if @last_commands[ -1 ] =~ /^delete_and_store_line_to_klipper/
          clip_filename = write_to_clip_file( removed_text << "\n" )
          `clipping="$(dcop klipper klipper getClipboardContents)\n$(cat #{clip_filename};printf "_")"; dcop klipper klipper setClipboardContents "${clipping%_}"`
        else
          send_to_klipper [ removed_text, "" ]
        end
      end
    end

    def deleteAndStoreLine
      removed_text = @current_buffer.deleteLine
      if removed_text
        clip = [ removed_text, "" ]
        if @last_commands[ -1 ] =~ /^deleteAndStoreLine/
          @clipboard.appendToClip clip
        else
          @clipboard.addClip clip
        end
      end
    end

    def delete_line_to_klipper
        removed_text = @current_buffer.deleteLine
        if removed_text
          send_to_klipper [ removed_text, "" ]
        end
    end

    def deleteLine
        removed_text = @current_buffer.deleteLine
        @clipboard.addClip( [ removed_text, "" ] ) if removed_text
    end

    def delete_to_EOL_to_klipper
        removed_text = @current_buffer.deleteToEOL
        if removed_text
          send_to_klipper removed_text
        end
    end

    def deleteToEOL
        removed_text = @current_buffer.deleteToEOL
        @clipboard.addClip( removed_text ) if removed_text
    end

    def evaluate( code_ = nil )
        if code_.nil?
            if @current_buffer.changing_selection
                selected_text = @current_buffer.copySelection[ 0 ]
            end
            code = getUserInput( "Ruby code: ", @rlh_general, ( selected_text or "" ), FUNCTIONS )
        else
            code = code_
        end

        if code
            begin
                eval code
            rescue Exception => e
                showException(
                    e,
                    [
                        "The code given to evaluate has a syntax error.",
                        "The code given to evaluate refers to a Diakonos command which does not exist, or is misspelled.",
                        "The code given to evaluate refers to a Diakonos command with missing arguments.",
                        "The code given to evaluate refers to a variable or method which does not exist.",
                    ]
                )
            end
        end
    end

    def find( dir_str = "down", case_sensitive = CASE_INSENSITIVE, regexp_source_ = nil, replacement = nil )
      direction = dir_str.toDirection
      if regexp_source_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copySelection[ 0 ]
        end
        starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

        regexp_source = getUserInput(
          "Search regexp: ",
          @rlh_search,
          ( selected_text or "" )
        ) { |input|
          if input.length > 1
            find_ direction, case_sensitive, input, nil, starting_row, starting_col, QUIET
          else
            @current_buffer.removeSelection Buffer::DONT_DISPLAY
            @current_buffer.clearMatches Buffer::DO_DISPLAY
          end
        }
      else
        regexp_source = regexp_source_
      end

      if regexp_source
        find_ direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, NOISY
      elsif starting_row and starting_col
        @current_buffer.clearMatches
        if @settings[ 'find.return_on_abort' ]
          @current_buffer.cursorTo starting_row, starting_col
        end
      end
    end

    def findAgain( dir_str = nil )
        if dir_str
            direction = dir_str.toDirection
            @current_buffer.findAgain( @last_search_regexps, direction )
        else
            @current_buffer.findAgain( @last_search_regexps )
        end
    end

    def findAndReplace
        searchAndReplace
    end

    def findExact( dir_str = "down", search_term_ = nil )
        if search_term_.nil?
            if @current_buffer.changing_selection
                selected_text = @current_buffer.copySelection[ 0 ]
            end
            search_term = getUserInput( "Search for: ", @rlh_search, ( selected_text or "" ) )
        else
            search_term = search_term_
        end
        if search_term
            direction = dir_str.toDirection
            regexp = [ Regexp.new( Regexp.escape( search_term ) ) ]
            @current_buffer.find( regexp, :direction => direction )
            @last_search_regexps = regexp
        end
    end

    def goToLineAsk
        input = getUserInput( "Go to [line number|+lines][,column number]: " )
        if input
            row = nil

            if input =~ /([+-]\d+)/
                row = @current_buffer.last_row + $1.to_i
                col = @current_buffer.last_col
            else
                input = input.split( /\D+/ ).collect { |n| n.to_i }
                if input.size > 0
                    if input[ 0 ] == 0
                        row = nil
                    else
                        row = input[ 0 ] - 1
                    end
                    if input[ 1 ]
                        col = input[ 1 ] - 1
                    end
                end
            end

            if row
                @current_buffer.goToLine( row, col )
            end
        end
    end

    def goToNamedBookmark( name_ = nil )
        if name_.nil?
            name = getUserInput "Bookmark name: "
        else
            name = name_
        end

        if name
            bookmark = @bookmarks[ name ]
            if bookmark
                switchTo( bookmark.buffer )
                bookmark.buffer.cursorTo( bookmark.row, bookmark.col, Buffer::DO_DISPLAY )
            else
                setILine "No bookmark named '#{name}'."
            end
        end
    end

    def goToNextBookmark
        @current_buffer.goToNextBookmark
    end

    def goToPreviousBookmark
        @current_buffer.goToPreviousBookmark
    end

    def goToTag( tag_ = nil )
        loadTags

        # If necessary, prompt for tag name.

        if tag_.nil?
            if @current_buffer.changing_selection
                selected_text = @current_buffer.copySelection[ 0 ]
            end
            tag_name = getUserInput( "Tag name: ", @rlh_general, ( selected_text or "" ), @tags.keys )
        else
            tag_name = tag_
        end

        tag_array = @tags[ tag_name ]
        if tag_array and tag_array.length > 0
            if i = tag_array.index( @last_tag )
                tag = ( tag_array[ i + 1 ] or tag_array[ 0 ] )
            else
                tag = tag_array[ 0 ]
            end
            @last_tag = tag
            @tag_stack.push [ @current_buffer.name, @current_buffer.last_row, @current_buffer.last_col ]
            if switchTo( @buffers[ tag.file ] )
                #@current_buffer.goToLine( 0 )
            else
                openFile( tag.file )
            end
            line_number = tag.command.to_i
            if line_number > 0
                @current_buffer.goToLine( line_number - 1 )
            else
                find( "down", CASE_SENSITIVE, tag.command )
            end
        elsif tag_name
            setILine "No such tag: '#{tag_name}'"
        end
    end

    def goToTagUnderCursor
        goToTag @current_buffer.wordUnderCursor
    end

    def grep( regexp_source = nil )
      grep_( regexp_source, @current_buffer )
    end

    def grep_buffers( regexp_source = nil )
      grep_( regexp_source, *@buffers.values )
    end

    def grep_session_dir( regexp_source = nil )
      grep_dir regexp_source, @session[ 'dir' ]
    end

    def grep_dir( regexp_source = nil, dir = nil )
      if dir.nil?
        dir = getUserInput( "Grep directory: ", @rlh_files, @session[ 'dir' ], nil, DONT_COMPLETE, :accept_dirs )
        return if dir.nil?
      end
      dir = File.expand_path( dir )

      original_buffer = @current_buffer
      if @current_buffer.changing_selection
        selected_text = @current_buffer.copySelection[ 0 ]
      end
      starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

      selected = getUserInput(
        "Grep regexp: ",
        @rlh_search,
        regexp_source || selected_text || ""
      ) { |input|
        next if input.length < 2
        escaped_input = input.gsub( /'/ ) { "\\047" }
        matching_files = `egrep '#{escaped_input}' -rniIl #{dir}`.split( /\n/ )

        grep_results = matching_files.map { |f|
          ::Diakonos.grep_array(
            Regexp.new( input ),
            File.read( f ).split( /\n/ ),
            settings[ 'grep.context' ],
            "#{File.basename( f )}:",
            f
          )
        }.flatten
        if settings[ 'grep.context' ] == 0
          join_str = "\n"
        else
          join_str = "\n---\n"
        end
        with_list_file do |list|
          list.puts grep_results.join( join_str )
        end

        list_buffer = openListBuffer
        list_buffer.highlightMatches Regexp.new( input )
        list_buffer.display
      }

      if selected
        spl = selected.split( "| " )
        if spl.size > 1
          openFile spl[ -1 ]
        end
      else
        original_buffer.cursorTo starting_row, starting_col
      end
    end

    def help( prefill = '' )
      if ! File.exist?( @help_dir ) || Dir[ "#{@help_dir}/*" ].size == 0
        setILine 'There are no help files installed.'
        return
      end

      open_help_buffer
      matching_docs = nil

      selected = getUserInput(
        "Search terms: ",
        @rlh_help,
        prefill,
        @help_tags
      ) { |input|
        next if input.length < 3 and input[ 0..0 ] != '/'

        matching_docs = matching_help_documents( input )
        with_list_file do |list|
          list.puts matching_docs.join( "\n" )
        end

        openListBuffer
      }

      close_help_buffer

      case selected
      when /\|/
        open_help_document selected
      when nil
        # Help search aborted; do nothing
      else
        # Not a selected help document
        if matching_docs.nil? or matching_docs.empty?
          matching_docs = matching_help_documents( selected )
        end

        case matching_docs.size
        when 1
          open_help_document matching_docs[ 0 ]
        when 0
          File.open( @error_filename, 'w' ) do |f|
            f.puts "There were no help documents matching your search."
            f.puts "(#{selected.strip})"
          end
          error_file = openFile @error_filename

          choice = getChoice(
            "Send your search terms to purepistos.net to help improve Diakonos?",
            [ CHOICE_YES, CHOICE_NO ]
          )
          case choice
          when CHOICE_YES
            require 'net/http'
            require 'uri'

            res = Net::HTTP.post_form(
              URI.parse( 'http://dh.purepistos.net/' ),
              { 'q' => selected }
            )
          # TODO: let them choose "never" and "always"
          end

          closeFile error_file
        else
          help selected
        end
      end
    end

    def indent
        if( @current_buffer.changing_selection )
            @do_display = false
            mark = @current_buffer.selection_mark
            if mark.end_col > 0
                end_row = mark.end_row
            else
                end_row = mark.end_row - 1
            end
            (mark.start_row..end_row).each do |row|
                @current_buffer.indent row, Buffer::DONT_DISPLAY
            end
            @do_display = true
            @current_buffer.display
        else
            @current_buffer.indent
        end
    end

    def insertSpaces( num_spaces )
        if num_spaces > 0
            @current_buffer.deleteSelection
            @current_buffer.insertString( " " * num_spaces )
            cursorRight( Buffer::STILL_TYPING, num_spaces )
        end
    end

    def insertTab
        typeCharacter( TAB )
    end

    def joinLines
        @current_buffer.joinLines( @current_buffer.currentRow, Buffer::STRIP_LINE )
    end

    def list_buffers
      with_list_file do |f|
        f.puts @buffers.keys.map { |name| "#{name}\n" }.sort
      end
      openListBuffer
      filename = getUserInput( "Switch to buffer: " )
      buffer = @buffers[ filename ]
      if buffer
        switchTo buffer
      end
    end

    def loadScript( name_ = nil )
        if name_.nil?
            name = getUserInput( "File to load as script: ", @rlh_files )
        else
            name = name_
        end

        if name
            thread = Thread.new( name ) do |f|
                begin
                    load( f )
                rescue Exception => e
                    showException(
                        e,
                        [
                            "The filename given does not exist.",
                            "The filename given is not accessible or readable.",
                            "The loaded script does not reference Diakonos commands as members of the global Diakonos object.  e.g. cursorBOL instead of $diakonos.cursorBOL",
                            "The loaded script has syntax errors.",
                            "The loaded script references objects or object members which do not exist."
                        ]
                    )
                end
                setILine "Loaded script '#{name}'."
            end

            loop do
                if thread.status != "run"
                    break
                else
                    sleep 0.1
                end
            end
            thread.join
        end
    end

    def load_session( session_id = nil )
      if session_id.nil?
        session_id = getUserInput( "Session: ", @rlh_sessions, @session_dir, nil, DO_COMPLETE )
      end
      return if session_id.nil? or session_id.empty?

      path = session_filepath_for( session_id )
      if not File.exist?( path )
        setILine "No such session: #{session_id}"
      else
        if pid_session?( @session[ 'filename' ] )
          File.delete @session[ 'filename' ]
        end
        @session = nil
        @buffers.each_value do |buffer|
          closeFile buffer
        end
        new_session( path )
        @session[ 'files' ].each do |file|
          openFile file
        end
      end
    end

    def name_session
      name = getUserInput( 'Session name: ' )
      if name
        new_session "#{@session_dir}/#{name}"
        save_session
      end
    end

    def newFile
        openFile
    end

    # Returns the buffer of the opened file, or nil.
    def openFile( filename = nil, read_only = false, force_revert = ASK_REVERT )
      do_open = true
      buffer = nil
      if filename.nil?
        buffer_key = @untitled_id
        @untitled_id += 1
      else
        if filename =~ /^(.+):(\d+)$/
          filename, line_number = $1, ( $2.to_i - 1 )
        end
        buffer_key = filename
        if(
          ( not force_revert ) and
          ( (existing_buffer = @buffers[ filename ]) != nil ) and
          ( filename !~ /\.diakonos/ ) and
          existing_buffer.file_different?
        )
          show_buffer_file_diff( existing_buffer ) do
            choice = getChoice(
              "Load on-disk version of #{existing_buffer.nice_name}?",
              [ CHOICE_YES, CHOICE_NO ]
            )
            case choice
            when CHOICE_NO
              do_open = false
            end
          end
        end

        if FileTest.exist?( filename )
          # Don't try to open non-files (i.e. directories, pipes, sockets, etc.)
          do_open &&= FileTest.file?( filename )
        end
      end

      if do_open
        # Is file readable?

        # Does the "file" utility exist?
        if(
          filename and
          @settings[ 'use_magic_file' ] and
          FileTest.exist?( "/usr/bin/file" ) and
          FileTest.exist?( filename ) and
          /\blisting\.txt\b/ !~ filename
        )
          file_type = `/usr/bin/file -L #{filename}`
          if file_type !~ /text/ and file_type !~ /empty$/
            choice = getChoice(
              "#{filename} does not appear to be readable.  Try to open it anyway?",
              [ CHOICE_YES, CHOICE_NO ],
              CHOICE_NO
            )
            case choice
            when CHOICE_NO
              do_open = false
            end

          end
        end

        if do_open
          buffer = Buffer.new( self, filename, buffer_key, read_only )
          runHookProcs( :after_open, buffer )
          @buffers[ buffer_key ] = buffer
          save_session
          if switchTo( buffer ) and line_number
            @current_buffer.goToLine( line_number, 0 )
          end
        end
      end

      buffer
    end

    def openFileAsk
      prefill = ''

      if @current_buffer
        if @current_buffer.current_line =~ %r#(/\w+)+/\w+\.\w+#
          prefill = $&
        elsif @current_buffer.name
          prefill = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
        end
      end

      if @settings[ 'fuzzy_file_find' ]
        prefill = ''
        finder_block = lambda { |input|
          finder = FuzzyFileFinder.new
          matches = finder.find( input ).sort_by { |m| [ -m[:score], m[:path] ] }
          with_list_file do |list|
            list.puts matches.map { |m| m[ :path ] }
          end
          openListBuffer
        }
      end
      file = getUserInput( "Filename: ", @rlh_files, prefill, &finder_block )

      if file
        openFile file
        updateStatusLine
        updateContextLine
      end
    end

    def open_matching_files( regexp = nil, search_root = nil )
      regexp ||= getUserInput( "Regexp: ", @rlh_search )
      return if regexp.nil?

      if @current_buffer.current_line =~ %r{\w*/[/\w.]+}
        prefill = $&
      else
        prefill = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
      end
      search_root ||= getUserInput( "Search within: ", @rlh_files, prefill )
      return if search_root.nil?

      files = `egrep -rl '#{regexp.gsub( /'/, "'\\\\''" )}' #{search_root}/*`.split( /\n/ )
      if files.any?
        if files.size > 5
            choice = getChoice( "Open #{files.size} files?", [ CHOICE_YES, CHOICE_NO ] )
            return if choice == CHOICE_NO
        end
        files.each do |f|
          openFile f
        end
        find 'down', CASE_SENSITIVE, regexp
      end
    end

    def operateOnString(
        ruby_code = getUserInput( 'Ruby code: ', @rlh_general, 'str.' )
    )
        if ruby_code
            str = @current_buffer.selected_string
            if str and not str.empty?
                @current_buffer.paste eval( ruby_code )
            end
        end
    end

    def operateOnLines(
        ruby_code = getUserInput( 'Ruby code: ', @rlh_general, 'lines.collect { |l| l }' )
    )
        if ruby_code
            lines = @current_buffer.selected_text
            if lines and not lines.empty?
                if lines[ -1 ].empty?
                    lines.pop
                    popped = true
                end
                new_lines = eval( ruby_code )
                if popped
                    new_lines << ''
                end
                @current_buffer.paste new_lines
            end
        end
    end

    def operateOnEachLine(
        ruby_code = getUserInput( 'Ruby code: ', @rlh_general, 'line.' )
    )
        if ruby_code
            lines = @current_buffer.selected_text
            if lines and not lines.empty?
                if lines[ -1 ].empty?
                    lines.pop
                    popped = true
                end
                new_lines = eval( "lines.collect { |line| #{ruby_code} }" )
                if popped
                    new_lines << ''
                end
                @current_buffer.paste new_lines
            end
        end
    end

    def pageUp
        if @current_buffer.pitchView( -main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
            cursorBOF
        end
        updateStatusLine
        updateContextLine
    end

    def pageDown
        if @current_buffer.pitchView( main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
            @current_buffer.cursorToEOF
        end
        updateStatusLine
        updateContextLine
    end

    def parsedIndent
        if( @current_buffer.changing_selection )
            @do_display = false
            mark = @current_buffer.selection_mark
            (mark.start_row..mark.end_row).each do |row|
                @current_buffer.parsedIndent row, Buffer::DONT_DISPLAY
            end
            @do_display = true
            @current_buffer.display
        else
            @current_buffer.parsedIndent
        end
        updateStatusLine
        updateContextLine
    end

    def paste
        @current_buffer.paste @clipboard.clip
    end

    def paste_from_klipper
      text = `dcop klipper klipper getClipboardContents`.split( "\n", -1 )
      text.pop  # getClipboardContents puts an extra newline on end
      @current_buffer.paste text
    end

    def playMacro( name = nil )
        macro, input_history = @macros[ name ]
        if input_history
            @macro_input_history = input_history.deep_clone
            if macro
                @playing_macro = true
                macro.each do |command|
                    eval command
                end
                @playing_macro = false
                @macro_input_history = nil
            end
        end
    end

    def popTag
        tag = @tag_stack.pop
        if tag
            if not switchTo( @buffers[ tag[ 0 ] ] )
                openFile( tag[ 0 ] )
            end
            @current_buffer.cursorTo( tag[ 1 ], tag[ 2 ], Buffer::DO_DISPLAY )
        else
            setILine "Tag stack empty."
        end
    end

    def print_mapped_function
      @capturing_mapping = true
      setILine "Type any chain of keystrokes or key chords, or press Enter to stop."
    end

    def printKeychain
      @capturing_keychain = true
      setILine "Type any chain of keystrokes or key chords, then press Enter..."
    end

    def quit
        @quitting = true
        to_all = nil
        @buffers.each_value do |buffer|
            if buffer.modified?
                switchTo buffer
                closure_choice = closeFile( buffer, to_all )
                case closure_choice
                    when CHOICE_CANCEL
                        @quitting = false
                        break
                    when CHOICE_YES_TO_ALL, CHOICE_NO_TO_ALL
                        to_all = closure_choice
                end
            end
        end
    end

    def removeNamedBookmark( name_ = nil )
        if name_.nil?
            name = getUserInput "Bookmark name: "
        else
            name = name_
        end

        if name
            bookmark = @bookmarks.delete name
            setILine "Removed bookmark #{bookmark.to_s}."
        end
    end

    def removeSelection
        @current_buffer.removeSelection
        updateStatusLine
    end

    def repeatLast
        eval @last_commands[ -1 ] if not @last_commands.empty?
    end

    # If the prompt is non-nil, ask the user yes or no question first.
    def revert( prompt = nil )
      do_revert = true

      if prompt
        show_buffer_file_diff do
          choice = getChoice(
            prompt,
            [ CHOICE_YES, CHOICE_NO ]
          )
          case choice
          when CHOICE_NO
            do_revert = false
          end
        end
      end

      if do_revert
        openFile( @current_buffer.name, Buffer::READ_WRITE, FORCE_REVERT )
      end
    end

    def saveFile( buffer = @current_buffer )
        buffer.save
        runHookProcs( :after_save, buffer )
    end

    def saveFileAs
        if @current_buffer and @current_buffer.name
            path = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
            file = getUserInput( "Filename: ", @rlh_files, path )
        else
            file = getUserInput( "Filename: ", @rlh_files )
        end
        if file
            old_name = @current_buffer.name
            if @current_buffer.save( file, PROMPT_OVERWRITE )
                @buffers.delete old_name
                @buffers[ @current_buffer.name ] = @current_buffer
                save_session
            end
        end
    end

    def select_all
      @current_buffer.select_all
    end

    def select_block( beginning = nil, ending = nil, including_ending = true )
      if beginning.nil?
        input = getUserInput( "Start at regexp: " )
        if input
          beginning = Regexp.new input
        end
      end
      if beginning and ending.nil?
        input = getUserInput( "End before regexp: " )
        if input
          ending = Regexp.new input
        end
      end
      if beginning and ending
        @current_buffer.select( beginning, ending, including_ending )
      end
    end

    def scrollDown
        @current_buffer.pitchView( @settings[ "view.scroll_amount" ] || 1 )
        updateStatusLine
        updateContextLine
    end

    def scrollUp
        if @settings[ "view.scroll_amount" ]
            @current_buffer.pitchView( -@settings[ "view.scroll_amount" ] )
        else
            @current_buffer.pitchView( -1 )
        end
        updateStatusLine
        updateContextLine
    end

    def searchAndReplace( case_sensitive = CASE_INSENSITIVE )
        find( "down", case_sensitive, nil, ASK_REPLACEMENT )
    end

    def seek( regexp_source, dir_str = "down" )
        if regexp_source
            direction = dir_str.toDirection
            regexp = Regexp.new( regexp_source )
            @current_buffer.seek( regexp, direction )
        end
    end

    def setBufferType( type_ = nil )
        if type_.nil?
            type = getUserInput "Content type: "
        else
            type = type_
        end

        if type
            if @current_buffer.setType( type )
                updateStatusLine
                updateContextLine
            end
        end
    end

    # If read_only is nil, the read_only state of the current buffer is toggled.
    # Otherwise, the read_only state of the current buffer is set to read_only.
    def setReadOnly( read_only = nil )
        if read_only
            @current_buffer.read_only = read_only
        else
            @current_buffer.read_only = ( not @current_buffer.read_only )
        end
        updateStatusLine
    end

    def set_session_dir
      path = getUserInput( "Session directory: ", @rlh_files, @session[ 'dir' ], nil, DONT_COMPLETE, :accept_dirs )
      if path
        @session[ 'dir' ] = File.expand_path( path )
        save_session
        setILine "Session dir changed to: #{@session['dir']}"
      else
        setILine "(Session dir is: #{@session['dir']})"
      end
    end

    def shell( command_ = nil, result_filename = 'shell-result.txt' )
        if command_.nil?
            command = getUserInput( "Command: ", @rlh_shell )
        else
            command = command_
        end

        if command
            command = subShellVariables( command )

            result_file = "#{@diakonos_home}/#{result_filename}"
            File.open( result_file , "w" ) do |f|
                f.puts command
                f.puts
                Curses::close_screen

                stdin, stdout, stderr = Open3.popen3( command )
                t1 = Thread.new do
                    stdout.each_line do |line|
                        f.puts line
                    end
                end
                t2 = Thread.new do
                    stderr.each_line do |line|
                        f.puts line
                    end
                end

                t1.join
                t2.join

                Curses::init_screen
                refreshAll
            end
            openFile result_file
        end
    end

    def execute( command_ = nil )
        if command_.nil?
            command = getUserInput( "Command: ", @rlh_shell )
        else
            command = command_
        end

        if command
            command = subShellVariables( command )

            Curses::close_screen

            success = system( command )
            if not success
                result = "Could not execute: #{command}"
            else
                result = "Return code: #{$?}"
            end

            Curses::init_screen
            refreshAll

            setILine result
        end
    end

    def pasteShellResult( command_ = nil )
        if command_.nil?
            command = getUserInput( "Command: ", @rlh_shell )
        else
            command = command_
        end

        if command
            command = subShellVariables( command )

            Curses::close_screen

            begin
                @current_buffer.paste( `#{command} 2<&1`.split( /\n/, -1 ) )
            rescue Exception => e
                debugLog e.message
                debugLog e.backtrace.join( "\n\t" )
                showException e
            end

            Curses::init_screen
            refreshAll
        end
    end

    # Send the Diakonos job to background, as if with Ctrl-Z
    def suspend
        Curses::close_screen
        Process.kill( "SIGSTOP", $PID )
        Curses::init_screen
        refreshAll
    end

    def toggleMacroRecording( name = nil )
        if @macro_history
            stopRecordingMacro
        else
            startRecordingMacro( name )
        end
    end

    def switchToBufferNumber( buffer_number_ )
        buffer_number = buffer_number_.to_i
        return if buffer_number < 1
        buffer_name = bufferNumberToName( buffer_number )
        if buffer_name
            switchTo( @buffers[ buffer_name ] )
        end
    end

    def switchToNextBuffer
      if @buffer_history.any?
        @buffer_history_pointer += 1
        if @buffer_history_pointer >= @buffer_history_pointer.size
          @buffer_history_pointer = @buffer_history_pointer.size - 1
          switchToBufferNumber( bufferToNumber( @current_buffer ) + 1 )
        else
          switchTo @buffer_history[ @buffer_history_pointer ]
        end
      else
        switchToBufferNumber( bufferToNumber( @current_buffer ) + 1 )
      end
    end

    def switchToPreviousBuffer
      if @buffer_history.any?
        @buffer_history_pointer -= 1
        if @buffer_history_pointer < 0
          @buffer_history_pointer = 0
          switchToBufferNumber( bufferToNumber( @current_buffer ) - 1 )
        else
          switchTo @buffer_history[ @buffer_history_pointer ]
        end
      else
        switchToBufferNumber( bufferToNumber( @current_buffer ) - 1 )
      end
    end

    def toggleBookmark
        @current_buffer.toggleBookmark
    end

    def toggleSelection
        @current_buffer.toggleSelection
        updateStatusLine
    end

    def toggleSessionSetting( key_ = nil, do_redraw = DONT_REDRAW )
        if key_.nil?
            key = getUserInput( "Setting: " )
        else
            key = key_
        end

        if key
            value = nil
            if @session[ 'settings' ][ key ].class == TrueClass or @session[ 'settings' ][ key ].class == FalseClass
                value = ! @session[ 'settings' ][ key ]
            elsif @settings[ key ].class == TrueClass or @settings[ key ].class == FalseClass
                value = ! @settings[ key ]
            end
            if value
                @session[ 'settings' ][ key ] = value
                redraw if do_redraw
                setILine "#{key} = #{value}"
            end
        end
    end

    def uncomment
      @current_buffer.uncomment
    end

    def undo( buffer = @current_buffer )
        buffer.undo
    end

    def unindent
        if( @current_buffer.changing_selection )
            @do_display = false
            mark = @current_buffer.selection_mark
            if mark.end_col > 0
                end_row = mark.end_row
            else
                end_row = mark.end_row - 1
            end
            (mark.start_row..end_row).each do |row|
                @current_buffer.unindent row, Buffer::DONT_DISPLAY
            end
            @do_display = true
            @current_buffer.display
        else
            @current_buffer.unindent
        end
    end

    def unundo( buffer = @current_buffer )
        buffer.unundo
    end

    def wrap_paragraph
      @current_buffer.wrap_paragraph
    end

  end
end