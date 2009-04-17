module Diakonos
  module Functions
    def add_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        @bookmarks[ name ] = Bookmark.new( @current_buffer, @current_buffer.current_row, @current_buffer.current_column, name )
        set_iline "Added bookmark #{@bookmarks[ name ].to_s}."
      end
    end

    # Begins selecting text by anchoring (marking) the start of a selection.
    def anchor_selection
      @current_buffer.anchor_selection
      update_status_line
    end

    # Move one character left, then delete one character.
    #
    # @see Diakonos::Buffer#delete
    def backspace
      delete  if( @current_buffer.changing_selection or cursor_left( Buffer::STILL_TYPING ) )
    end

    # Insert a carriage return (newline) at the current cursor location.
    # Deletes any currently selected text.
    def carriage_return
      @current_buffer.carriage_return
      @current_buffer.delete_selection
    end

    def change_session_setting( key_ = nil, value = nil, do_redraw = DONT_REDRAW )
      if key_.nil?
        key = get_user_input( "Setting: " )
      else
        key = key_
      end

      if key
        if value.nil?
          value = get_user_input( "Value: " )
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
        redraw  if do_redraw
        set_iline "#{key} = #{value}"
      end
    end

    # Removes the highlighting from any text that matches the most recent
    # search.
    def clear_matches
      @current_buffer.clear_matches Buffer::DO_DISPLAY
    end

    def close_code
      @current_buffer.close_code
    end

    # Closes a buffer.
    #
    # @param [Diakonos::Buffer] buffer
    #   The buffer to close.  If no buffer is provided, defaults to the current buffer.
    # @param [Fixnum] to_all
    #   the CHOICE to assume for the prompt.
    # @return [Fixnum] the choice the user made, or nil if the user was not prompted to choose.
    # @see Diakonos::CHOICE_YES
    # @see Diakonos::CHOICE_NO
    def close_file( buffer = @current_buffer, to_all = nil )
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
              choice = get_choice(
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
              save_file buffer
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
            ( @buffers.key( buf ) == del_buffer_key )
          ) do
            buf = @buffer_stack.pop
          end
          if @buffers.values.include?( buf )
            to_switch_to = buf
          end

          if to_switch_to
            switch_to( to_switch_to )
          elsif previous_buffer
            switch_to( previous_buffer )
          else
            # No buffers left.  Open a new blank one.
            open_file
          end

          @buffers.delete del_buffer_key
          save_session

          update_status_line
          update_context_line
        end
      else
        log "No such buffer: #{buffer.name}"
      end

      choice
    end

    def collapse_whitespace
      @current_buffer.collapse_whitespace
    end

    def columnize( delimiter = nil, num_spaces_padding = 0 )
      if delimiter.nil?
        delimiter = get_user_input(
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

    def copy_selection
      @clipboard.add_clip @current_buffer.copy_selection
      remove_selection
    end

    def copy_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        remove_selection
      end
    end

    # Returns true iff the cursor changed positions
    def cursor_down
      @current_buffer.cursor_to(
        @current_buffer.last_row + 1,
        @current_buffer.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    # Returns true iff the cursor changed positions
    def cursor_left( stopped_typing = Buffer::STOPPED_TYPING )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col - 1,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    def cursor_right( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
      @current_buffer.cursor_to(
        @current_buffer.last_row,
        @current_buffer.last_col + amount,
        Buffer::DO_DISPLAY,
        stopped_typing
      )
    end

    # Returns true iff the cursor changed positions
    def cursor_up
      @current_buffer.cursor_to(
        @current_buffer.last_row - 1,
        @current_buffer.last_col,
        Buffer::DO_DISPLAY,
        Buffer::STOPPED_TYPING,
        DONT_ADJUST_ROW
      )
    end

    def cursor_bof
      @current_buffer.cursor_to( 0, 0, Buffer::DO_DISPLAY )
    end

    def cursor_bol
      @current_buffer.cursor_to_bol
    end

    def cursor_eol
      @current_buffer.cursor_to_eol
    end

    def cursor_eof
      @current_buffer.cursor_to_eof
    end

    # Top of view
    def cursor_tov
      @current_buffer.cursor_to_tov
    end

    # Bottom of view
    def cursor_bov
      @current_buffer.cursor_to_bov
    end

    def cursor_return( dir_str = "backward" )
      stack_pointer, stack_size = @current_buffer.cursor_return( direction_of( dir_str, :backward ) )
      set_iline( "Location: #{stack_pointer+1}/#{stack_size}" )
    end

    def cut_selection
      delete  if @clipboard.add_clip( @current_buffer.copy_selection )
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
      removed_text = @current_buffer.delete_line
      if removed_text
        if @last_commands[ -1 ] =~ /^delete_and_store_line_to_klipper/
          new_clip = escape_quotes( `dcop klipper klipper getClipboardContents`.chomp + removed_text + "\n" )
          `dcop klipper klipper setClipboardContents '#{new_clip}'`
        else
          send_to_klipper [ removed_text, "" ]
        end
      end
    end

    def delete_and_store_line
      removed_text = @current_buffer.delete_line
      if removed_text
        clip = [ removed_text, "" ]
        if @last_commands[ -1 ] =~ /^delete_and_store_line/
          @clipboard.append_to_clip clip
        else
          @clipboard.add_clip clip
        end
      end
    end

    def delete_line_to_klipper
      removed_text = @current_buffer.delete_line
      if removed_text
        send_to_klipper [ removed_text, "" ]
      end
    end

    def delete_line
      removed_text = @current_buffer.delete_line
      @clipboard.add_clip( [ removed_text, "" ] ) if removed_text
    end

    def delete_to( char = nil )
      if char.nil?
        set_iline "Type character to delete to..."
        char = @win_main.getch
        set_iline
      end
      if char
        removed_text = @current_buffer.delete_to char
        if removed_text
          @clipboard.add_clip removed_text
        else
          set_iline "'#{char}' not found."
        end
      end
    end

    def delete_to_and_from( char = nil )
      if char.nil?
        set_iline "Type character to delete to and from..."
        char = @win_main.getch
        set_iline
      end
      if char
        removed_text = @current_buffer.delete_to_and_from char
        if removed_text
          @clipboard.add_clip( [ removed_text ] )
        else
          set_iline "'#{char}' not found."
        end
      end
    end

    def delete_to_EOL_to_klipper
      removed_text = @current_buffer.delete_to_eol
      if removed_text
        send_to_klipper removed_text
      end
    end

    def delete_to_eol
      removed_text = @current_buffer.delete_to_eol
      @clipboard.add_clip( removed_text ) if removed_text
    end

    def evaluate( code_ = nil )
      if code_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        code = get_user_input( "Ruby code: ", @rlh_general, ( selected_text or "" ), ::Diakonos::Functions.public_instance_methods )
      else
        code = code_
      end

      if code
        begin
          eval code
        rescue Exception => e
          show_exception(
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

    # Worker method for find function.
    def find_( direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, quiet )
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
            case_sensitive ? nil : Regexp::IGNORECASE
          )
          $VERBOSE = warning_verbosity
        rescue RegexpError => e
          if not exception_thrown
            exception_thrown = e
            source = Regexp.escape( source )
            retry
          else
            raise e
          end
        end
      end

      if replacement == ASK_REPLACEMENT
        replacement = get_user_input( "Replace with: ", @rlh_search )
      end

      if exception_thrown and not quiet
        set_iline( "Searching literally; #{exception_thrown.message}" )
      end

      @current_buffer.find(
        regexps,
        :direction          => direction,
        :replacement        => replacement,
        :starting_row       => starting_row,
        :starting_col       => starting_col,
        :quiet              => quiet,
        :show_context_after => @settings[ 'find.show_context_after' ]
      )
      @last_search_regexps = regexps
    end

    def find( dir_str = "down", case_sensitive = CASE_INSENSITIVE, regexp_source_ = nil, replacement = nil )
      direction = direction_of( dir_str )
      if regexp_source_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

        regexp_source = get_user_input(
          "Search regexp: ",
          @rlh_search,
          ( selected_text or "" )
        ) { |input|
          if input.length > 1
            find_ direction, case_sensitive, input, nil, starting_row, starting_col, QUIET
          else
            @current_buffer.remove_selection Buffer::DONT_DISPLAY
            @current_buffer.clear_matches Buffer::DO_DISPLAY
          end
        }
      else
        regexp_source = regexp_source_
      end

      if regexp_source
        find_ direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, NOISY
      elsif starting_row and starting_col
        @current_buffer.clear_matches
        if @settings[ 'find.return_on_abort' ]
          @current_buffer.cursor_to starting_row, starting_col, Buffer::DO_DISPLAY
        end
      end
    end

    def find_again( dir_str = nil )
      if dir_str
        direction = direction_of( dir_str )
        @current_buffer.find_again( @last_search_regexps, direction )
      else
        @current_buffer.find_again( @last_search_regexps )
      end
    end

    def find_exact( dir_str = "down", search_term_ = nil )
      if search_term_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        search_term = get_user_input( "Search for: ", @rlh_search, ( selected_text or "" ) )
      else
        search_term = search_term_
      end
      if search_term
        direction = direction_of( dir_str )
        regexp = [ Regexp.new( Regexp.escape( search_term ) ) ]
        @current_buffer.find( regexp, :direction => direction )
        @last_search_regexps = regexp
      end
    end

    def go_block_outer
      @current_buffer.go_block_outer
    end
    def go_block_inner
      @current_buffer.go_block_inner
    end
    def go_block_next
      @current_buffer.go_block_next
    end
    def go_block_previous
      @current_buffer.go_block_previous
    end

    def go_to_line_ask
      input = get_user_input( "Go to [line number|+lines][,column number]: " )
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
          @current_buffer.go_to_line( row, col )
        end
      end
    end

    def go_to_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        bookmark = @bookmarks[ name ]
        if bookmark
          switch_to( bookmark.buffer )
          bookmark.buffer.cursor_to( bookmark.row, bookmark.col, Buffer::DO_DISPLAY )
        else
          set_iline "No bookmark named '#{name}'."
        end
      end
    end

    def go_to_next_bookmark
      @current_buffer.go_to_next_bookmark
    end

    def go_to_previous_bookmark
      @current_buffer.go_to_previous_bookmark
    end

    def go_to_tag( tag_ = nil )
      load_tags

      # If necessary, prompt for tag name.

      if tag_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        tag_name = get_user_input( "Tag name: ", @rlh_general, ( selected_text or "" ), @tags.keys )
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
        if switch_to( @buffers[ tag.file ] )
          #@current_buffer.go_to_line( 0 )
        else
          open_file tag.file
        end
        line_number = tag.command.to_i
        if line_number > 0
          @current_buffer.go_to_line( line_number - 1 )
        else
          find( "down", CASE_SENSITIVE, tag.command )
        end
      elsif tag_name
        set_iline "No such tag: '#{tag_name}'"
      end
    end

    def go_to_tag_under_cursor
      go_to_tag @current_buffer.word_under_cursor
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
        dir = get_user_input( "Grep directory: ", @rlh_files, @session[ 'dir' ], nil, DONT_COMPLETE, :accept_dirs )
        return if dir.nil?
      end
      dir = File.expand_path( dir )

      original_buffer = @current_buffer
      if @current_buffer.changing_selection
        selected_text = @current_buffer.copy_selection[ 0 ]
      end
      starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

      selected = get_user_input(
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

        list_buffer = open_list_buffer
        regexp = nil
        begin
          list_buffer.highlight_matches Regexp.new( input )
        rescue RegexpError => e
          # ignore
        end
        list_buffer.display
      }

      if selected
        spl = selected.split( "| " )
        if spl.size > 1
          open_file spl[ -1 ]
        end
      else
        original_buffer.cursor_to starting_row, starting_col
      end
    end

    def help( prefill = '' )
      if ! File.exist?( @help_dir ) || Dir[ "#{@help_dir}/*" ].size == 0
        set_iline 'There are no help files installed.'
        return
      end

      open_help_buffer
      matching_docs = nil

      selected = get_user_input(
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

        open_list_buffer
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
          error_file = open_file( @error_filename )

          choice = get_choice(
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

          close_file error_file
        else
          help selected
        end
      end
    end

    def indent
      if ! @current_buffer.changing_selection
        @current_buffer.indent
      else
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
      end
    end

    def insert_spaces( num_spaces )
      if num_spaces > 0
        @current_buffer.delete_selection
        @current_buffer.insert_string( " " * num_spaces )
        cursor_right( Buffer::STILL_TYPING, num_spaces )
      end
    end

    def insert_tab
      type_character TAB
    end

    def join_lines
      @current_buffer.join_lines( @current_buffer.current_row, Buffer::STRIP_LINE )
    end

    def list_buffers
      with_list_file do |f|
        f.puts @buffers.keys.map { |name| "#{name}\n" }.sort
      end
      open_list_buffer
      filename = get_user_input( "Switch to buffer: " )
      buffer = @buffers[ filename ]
      if buffer
        switch_to buffer
      end
    end

    def load_script( name_ = nil )
      if name_.nil?
        name = get_user_input( "File to load as script: ", @rlh_files )
      else
        name = name_
      end

      if name
        thread = Thread.new( name ) do |f|
          begin
            load( f )
          rescue Exception => e
            show_exception(
              e,
              [
                "The filename given does not exist.",
                "The filename given is not accessible or readable.",
                "The loaded script does not reference Diakonos commands as members of the global Diakonos object.  e.g. cursor_bol instead of $diakonos.cursor_bol",
                "The loaded script has syntax errors.",
                "The loaded script references objects or object members which do not exist."
              ]
            )
          end
          set_iline "Loaded script '#{name}'."
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
        session_id = get_user_input( "Session: ", @rlh_sessions, @session_dir, nil, DO_COMPLETE )
      end
      return if session_id.nil? or session_id.empty?

      path = session_filepath_for( session_id )
      if not File.exist?( path )
        set_iline "No such session: #{session_id}"
      else
        if pid_session?( @session[ 'filename' ] )
          File.delete @session[ 'filename' ]
        end
        @session = nil
        @buffers.each_value do |buffer|
          close_file buffer
        end
        new_session( path )
        @session[ 'files' ].each do |file|
          open_file file
        end
      end
    end

    def name_session
      name = get_user_input( 'Session name: ' )
      if name
        new_session "#{@session_dir}/#{name}"
        save_session
      end
    end

    # Returns the buffer of the opened file, or nil.
    def open_file( filename = nil, read_only = false, force_revert = ASK_REVERT, last_row = nil, last_col = nil )
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
            choice = get_choice(
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
            choice = get_choice(
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
          run_hook_procs( :after_open, buffer )
          @buffers[ buffer_key ] = buffer
          save_session
          if switch_to( buffer )
            if line_number
              @current_buffer.go_to_line( line_number, 0 )
            elsif last_row && last_col
              @current_buffer.cursor_to( last_row, last_col, Buffer::DO_DISPLAY )
            end
          end
        end
      end

      buffer
    end
    alias_method :new_file, :open_file

    def open_file_ask
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
          finder = FuzzyFileFinder.new( @session[ 'dir' ] )
          matches = finder.find( input ).sort_by { |m| [ -m[:score], m[:path] ] }
          with_list_file do |list|
            list.puts matches.map { |m| m[ :path ] }
          end
          open_list_buffer
        }
      end
      file = get_user_input( "Filename: ", @rlh_files, prefill, &finder_block )

      if file
        open_file file
        update_status_line
        update_context_line
      end
    end

    def open_matching_files( regexp = nil, search_root = nil )
      regexp ||= get_user_input( "Regexp: ", @rlh_search )
      return if regexp.nil?

      if @current_buffer.current_line =~ %r{\w*/[/\w.]+}
        prefill = $&
      else
        prefill = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
      end
      search_root ||= get_user_input( "Search within: ", @rlh_files, prefill )
      return if search_root.nil?

      files = `egrep -rl '#{regexp.gsub( /'/, "'\\\\''" )}' #{search_root}/*`.split( /\n/ )
      if files.any?
        if files.size > 5
            choice = get_choice( "Open #{files.size} files?", [ CHOICE_YES, CHOICE_NO ] )
            return if choice == CHOICE_NO
        end
        files.each do |f|
          open_file f
        end
        find 'down', CASE_SENSITIVE, regexp
      end
    end

    def operate_on_string(
        ruby_code = get_user_input( 'Ruby code: ', @rlh_general, 'str.' )
    )
      if ruby_code
        str = @current_buffer.selected_string
        if str and not str.empty?
          @current_buffer.paste eval( ruby_code )
        end
      end
    end

    def operate_on_lines(
        ruby_code = get_user_input( 'Ruby code: ', @rlh_general, 'lines.collect { |l| l }' )
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

    def operate_on_each_line(
        ruby_code = get_user_input( 'Ruby code: ', @rlh_general, 'line.' )
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

    def page_up
      if @current_buffer.pitch_view( -main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        cursor_bof
      end
      update_status_line
      update_context_line
    end

    def page_down
      if @current_buffer.pitch_view( main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
        @current_buffer.cursor_to_eof
      end
      update_status_line
      update_context_line
    end

    def parsed_indent
      if( @current_buffer.changing_selection )
        @do_display = false
        mark = @current_buffer.selection_mark
        (mark.start_row..mark.end_row).each do |row|
          @current_buffer.parsed_indent row, Buffer::DONT_DISPLAY
        end
        @do_display = true
        @current_buffer.display
      else
        @current_buffer.parsed_indent
      end
      update_status_line
      update_context_line
    end

    def paste
      @current_buffer.paste @clipboard.clip
    end

    def paste_from_klipper
      text = `dcop klipper klipper getClipboardContents`.split( "\n", -1 )
      text.pop  # getClipboardContents puts an extra newline on end
      @current_buffer.paste text
    end

    def play_macro( name = nil )
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

    def pop_tag
      tag = @tag_stack.pop
      if tag
        if not switch_to( @buffers[ tag[ 0 ] ] )
          open_file tag[ 0 ]
        end
        @current_buffer.cursor_to( tag[ 1 ], tag[ 2 ], Buffer::DO_DISPLAY )
      else
        set_iline "Tag stack empty."
      end
    end

    def print_mapped_function
      @capturing_mapping = true
      set_iline "Type any chain of keystrokes or key chords, or press Enter to stop."
    end

    def print_keychain
      @capturing_keychain = true
      set_iline "Type any chain of keystrokes or key chords, then press Enter..."
    end

    def quit
      @quitting = true
      to_all = nil
      @buffers.each_value do |buffer|
        if buffer.modified?
          switch_to buffer
          closure_choice = close_file( buffer, to_all )
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

    def remove_named_bookmark( name_ = nil )
      if name_.nil?
        name = get_user_input "Bookmark name: "
      else
        name = name_
      end

      if name
        bookmark = @bookmarks.delete name
        set_iline "Removed bookmark #{bookmark.to_s}."
      end
    end

    def remove_selection
      @current_buffer.remove_selection
      update_status_line
    end

    def repeat_last
      eval @last_commands[ -1 ] if not @last_commands.empty?
    end

    # If the prompt is non-nil, ask the user yes or no question first.
    def revert( prompt = nil )
      do_revert = true

      if prompt
        show_buffer_file_diff do
          choice = get_choice(
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
        open_file(
          @current_buffer.name,
          Buffer::READ_WRITE,
          FORCE_REVERT,
          @current_buffer.last_row,
          @current_buffer.last_col
        )
      end
    end

    def save_file( buffer = @current_buffer )
      buffer.save
      run_hook_procs( :after_save, buffer )
    end

    def save_file_as
      if @current_buffer and @current_buffer.name
        path = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
        file = get_user_input( "Filename: ", @rlh_files, path )
      else
        file = get_user_input( "Filename: ", @rlh_files )
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
        input = get_user_input( "Start at regexp: " )
        if input
          beginning = Regexp.new input
        end
      end
      if beginning and ending.nil?
        input = get_user_input( "End before regexp: " )
        if input
          ending = Regexp.new input
        end
      end
      if beginning and ending
        @current_buffer.select( beginning, ending, including_ending )
      end
    end

    def selection_mode_block
      @current_buffer.selection_mode_block
      update_status_line
    end
    def selection_mode_normal
      @current_buffer.selection_mode_normal
      update_status_line
    end

    def scroll_down
      @current_buffer.pitch_view( @settings[ "view.scroll_amount" ] || 1 )
      update_status_line
      update_context_line
    end

    def scroll_up
      if @settings[ "view.scroll_amount" ]
        @current_buffer.pitch_view( -@settings[ "view.scroll_amount" ] )
      else
        @current_buffer.pitch_view( -1 )
      end
      update_status_line
      update_context_line
    end

    def search_and_replace( case_sensitive = CASE_INSENSITIVE )
      find( "down", case_sensitive, nil, ASK_REPLACEMENT )
    end
    alias_method :find_and_replace, :search_and_replace

    def seek( regexp_source, dir_str = "down" )
      if regexp_source
        direction = direction_of( dir_str )
        regexp = Regexp.new( regexp_source )
        @current_buffer.seek( regexp, direction )
      end
    end

    def set_buffer_type( type_ = nil )
      if type_.nil?
        type = get_user_input "Content type: "
      else
        type = type_
      end

      if type
        if @current_buffer.set_type( type )
          update_status_line
          update_context_line
        end
      end
    end

    # If read_only is nil, the read_only state of the current buffer is toggled.
    # Otherwise, the read_only state of the current buffer is set to read_only.
    def set_read_only( read_only = nil )
      if read_only
        @current_buffer.read_only = read_only
      else
        @current_buffer.read_only = ( not @current_buffer.read_only )
      end
      update_status_line
    end

    def set_session_dir
      path = get_user_input( "Session directory: ", @rlh_files, @session[ 'dir' ], nil, DONT_COMPLETE, :accept_dirs )
      if path
        @session[ 'dir' ] = File.expand_path( path )
        save_session
        set_iline "Session dir changed to: #{@session['dir']}"
      else
        set_iline "(Session dir is: #{@session['dir']})"
      end
    end

    def showClips
      clip_filename = @diakonos_home + "/clips.txt"
      File.open( clip_filename, "w" ) do |f|
        @clipboard.each do |clip|
          f.puts clip
          f.puts "---------------------------"
        end
      end
      open_file clip_filename
    end

    def subShellVariables( string )
      return  if string.nil?

      retval = string.dup

      # Current buffer filename
      retval.gsub!( /\$f/, ( $1 or "" ) + File.expand_path( @current_buffer.name || "" ) )
      # Current buffer dir
      retval.gsub!( /\$d/, ( $1 or "" ) + File.dirname( File.expand_path( @current_buffer.name || '' ) ) )

      # space-separated list of all buffer filenames
      name_array = Array.new
      @buffers.each_value do |b|
        name_array.push b.name
      end
      retval.gsub!( /\$F/, ( $1 or "" ) + ( name_array.join(' ') or "" ) )

      # Get user input, sub it in
      if retval =~ /\$i/
        user_input = get_user_input( "Argument: ", @rlh_shell, @current_buffer.selected_string )
        retval.gsub!( /\$i/, user_input )
      end

      # Current clipboard text
      if retval =~ /\$c/
        clip_filename = @diakonos_home + "/clip.txt"
        File.open( clip_filename, "w" ) do |clipfile|
          if @clipboard.clip
            clipfile.puts( @clipboard.clip.join( "\n" ) )
          end
        end
        retval.gsub!( /\$c/, clip_filename )
      end

      # Current klipper (KDE clipboard) text
      if retval =~ /\$k/
        clip_filename = @diakonos_home + "/clip.txt"
        File.open( clip_filename, "w" ) do |clipfile|
          clipfile.puts( `dcop klipper klipper getClipboardContents` )
        end
        retval.gsub!( /\$k/, clip_filename )
      end

      # Currently selected text
      if retval =~ /\$s/
        text_filename = @diakonos_home + "/selected.txt"

        File.open( text_filename, "w" ) do |textfile|
          selected_text = @current_buffer.selected_text
          if selected_text
            textfile.puts( selected_text.join( "\n" ) )
          end
        end
        retval.gsub!( /\$s/, text_filename )
      end

      retval
    end

    def shell( command_ = nil, result_filename = 'shell-result.txt' )
      if command_.nil?
        command = get_user_input( "Command: ", @rlh_shell )
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
          refresh_all
        end
        open_file result_file
      end
    end

    def execute( command_ = nil )
      if command_.nil?
        command = get_user_input( "Command: ", @rlh_shell )
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
        refresh_all

        set_iline result
      end
    end

    def pasteShellResult( command_ = nil )
      if command_.nil?
        command = get_user_input( "Command: ", @rlh_shell )
      else
        command = command_
      end

      if command
        command = subShellVariables( command )

        Curses::close_screen

        begin
          @current_buffer.paste( `#{command} 2<&1`.split( /\n/, -1 ) )
        rescue Exception => e
          debug_log e.message
          debug_log e.backtrace.join( "\n\t" )
          show_exception e
        end

        Curses::init_screen
        refresh_all
      end
    end

    def spawn( command_ = nil )
      if command_.nil?
        command = get_user_input( "Command: ", @rlh_shell )
      else
        command = command_
      end

      return  if command.nil?

      command = subShellVariables( command )

      Thread.new do
        if system( command )
          set_iline "Return code #{$?} from '#{command}'"
        else
          set_iline "Error code #{$?} executing '#{command}'"
        end
      end
    end

    # Send the Diakonos job to background, as if with Ctrl-Z
    def suspend
      Curses::close_screen
      Process.kill( "SIGSTOP", $PID )
      Curses::init_screen
      refresh_all
    end

    def toggleMacroRecording( name = nil )
      if @macro_history
        stop_recording_macro
      else
        start_recording_macro name
      end
    end

    def switchToBufferNumber( buffer_number_ )
      buffer_number = buffer_number_.to_i
      return  if buffer_number < 1
      buffer_name = buffer_number_to_name( buffer_number )
      if buffer_name
        switch_to( @buffers[ buffer_name ] )
      end
    end

    def switchToNextBuffer
      if @buffer_history.any?
        @buffer_history_pointer += 1
        if @buffer_history_pointer >= @buffer_history_pointer.size
          @buffer_history_pointer = @buffer_history_pointer.size - 1
          switchToBufferNumber( buffer_to_number( @current_buffer ) + 1 )
        else
          switch_to @buffer_history[ @buffer_history_pointer ]
        end
      else
        switchToBufferNumber( buffer_to_number( @current_buffer ) + 1 )
      end
    end

    def switchToPreviousBuffer
      if @buffer_history.any?
        @buffer_history_pointer -= 1
        if @buffer_history_pointer < 0
          @buffer_history_pointer = 0
          switchToBufferNumber( buffer_to_number( @current_buffer ) - 1 )
        else
          switch_to @buffer_history[ @buffer_history_pointer ]
        end
      else
        switchToBufferNumber( buffer_to_number( @current_buffer ) - 1 )
      end
    end

    def toggleBookmark
      @current_buffer.toggle_bookmark
    end

    def toggleSelection
      @current_buffer.toggle_selection
      update_status_line
    end

    def toggleSessionSetting( key_ = nil, do_redraw = DONT_REDRAW )
      key = key_ || get_user_input( "Setting: " )
      return  if key.nil?

      value = nil
      if @session[ 'settings' ][ key ].class == TrueClass or @session[ 'settings' ][ key ].class == FalseClass
        value = ! @session[ 'settings' ][ key ]
      elsif @settings[ key ].class == TrueClass or @settings[ key ].class == FalseClass
        value = ! @settings[ key ]
      end
      if value != nil   # explicitly true or false
        @session[ 'settings' ][ key ] = value
        redraw  if do_redraw
        set_iline "#{key} = #{value}"
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