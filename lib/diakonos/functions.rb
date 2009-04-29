module Diakonos
  module Functions

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
      type = type_ || get_user_input( "Content type: " )

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

    def show_clips
      clip_filename = @diakonos_home + "/clips.txt"
      File.open( clip_filename, "w" ) do |f|
        @clipboard.each do |clip|
          f.puts clip
          f.puts "---------------------------"
        end
      end
      open_file clip_filename
    end

    def sub_shell_variables( string )
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
        command = sub_shell_variables( command )

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
        command = sub_shell_variables( command )

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

    def paste_shell_result( command_ = nil )
      if command_.nil?
        command = get_user_input( "Command: ", @rlh_shell )
      else
        command = command_
      end

      if command
        command = sub_shell_variables( command )

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

      command = sub_shell_variables( command )

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

    def toggle_macro_recording( name = nil )
      if @macro_history
        stop_recording_macro
      else
        start_recording_macro name
      end
    end

    def switch_to_buffer_number( buffer_number_ )
      buffer_number = buffer_number_.to_i
      return  if buffer_number < 1
      buffer_name = buffer_number_to_name( buffer_number )
      if buffer_name
        switch_to( @buffers[ buffer_name ] )
      end
    end

    def switch_to_next_buffer
      if @buffer_history.any?
        @buffer_history_pointer += 1
        if @buffer_history_pointer >= @buffer_history_pointer.size
          @buffer_history_pointer = @buffer_history_pointer.size - 1
          switch_to_buffer_number( buffer_to_number( @current_buffer ) + 1 )
        else
          switch_to @buffer_history[ @buffer_history_pointer ]
        end
      else
        switch_to_buffer_number( buffer_to_number( @current_buffer ) + 1 )
      end
    end

    def switch_to_previous_buffer
      if @buffer_history.any?
        @buffer_history_pointer -= 1
        if @buffer_history_pointer < 0
          @buffer_history_pointer = 0
          switch_to_buffer_number( buffer_to_number( @current_buffer ) - 1 )
        else
          switch_to @buffer_history[ @buffer_history_pointer ]
        end
      else
        switch_to_buffer_number( buffer_to_number( @current_buffer ) - 1 )
      end
    end

    def toggle_bookmark
      @current_buffer.toggle_bookmark
    end

    def toggle_selection
      @current_buffer.toggle_selection
      update_status_line
    end

    def toggle_session_setting( key_ = nil, do_redraw = DONT_REDRAW )
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