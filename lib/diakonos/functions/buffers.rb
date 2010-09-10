module Diakonos
  module Functions

    # Closes a buffer.
    #
    # @param [Diakonos::Buffer] buffer
    #   The buffer to close.  If no buffer is provided, defaults to the current buffer.
    # @param [Fixnum] to_all
    #   The CHOICE to assume for the prompt.
    # @return [Fixnum] the choice the user made, or nil if the user was not prompted to choose.
    # @see Diakonos::CHOICE_YES
    # @see Diakonos::CHOICE_NO
    def close_file( buffer = buffer_current, to_all = nil )
      return nil  if buffer.nil?

      choice = nil
      if ! @buffers.has_value?( buffer )
        log "No such buffer: #{buffer.name}"
        return nil
      end

      do_closure = true

      if buffer.modified? && ! buffer.read_only
        if to_all
          choice = to_all
        else
          choices = [ CHOICE_YES, CHOICE_NO, CHOICE_CANCEL ]
          if @quitting
            choices.concat [ CHOICE_YES_TO_ALL, CHOICE_NO_TO_ALL ]
          end
          choice = get_choice(
            "Save changes to #{buffer.nice_name}?",
            choices,
            CHOICE_CANCEL
          )
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

      if do_closure
        del_buffer_key = nil
        del_buffer = nil
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
            del_buffer = buf
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
        cursor_stack_remove_buffer del_buffer
        save_session

        update_status_line
        update_context_line
      end

      choice
    end

    # Opens the special "buffer selection" buffer, and prompts the user
    # to select a buffer.  The user can select a buffer either with the
    # arrow keys and the Enter key, or by pressing the key corresponding
    # to an index presented in a left-hand column in the list.
    def list_buffers
      bullets = ('0'..'9').to_a + ('a'..'z').to_a
      with_list_file do |f|
        @buffers.keys.sort.each_with_index do |name, index|
          bullet = bullets[ index ]
          if bullet
            bullet << '  '
          end
          f.puts "#{bullet}#{name}"
        end
      end
      open_list_buffer
      filename = get_user_input( "Switch to buffer: ", numbered_list: true )
      buffer = @buffers[ filename ]
      if buffer
        switch_to buffer
      end
    end

    # Opens a file into a new Buffer.
    # @param filename
    #   The file to open.  If nil, an empty, unnamed buffer is opened.
    # @param [Hash] meta
    #   metadata containing additional information on how to open the file
    # @option meta [Hash] 'cursor' (nil)
    #   A Hash containing the 'row' and 'col' to position the cursor after opening.
    # @option meta [Hash] 'display' (nil)
    #   A Hash containing the 'top_line' and 'left_column' to use to position
    #   the view after opening.
    # @return [Buffer] the buffer of the opened file
    # @return [NilClass] nil on failure
    def open_file( filename = nil, meta = {} )
      read_only    = !!meta[ 'read_only' ]
      force_revert = meta[ 'revert' ] || ASK_REVERT
      if meta[ 'cursor' ]
        last_row = meta[ 'cursor' ][ 'row' ]
        last_col = meta[ 'cursor' ][ 'col' ]
      end
      if meta[ 'display' ]
        top_line    = meta[ 'display' ][ 'top_line' ]
        left_column = meta[ 'display' ][ 'left_column' ]
      end

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
          ( not force_revert ) &&
          ( (existing_buffer = @buffers[ filename ]) != nil ) &&
          ( filename !~ /\.diakonos/ ) &&
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
          filename &&
          @settings[ 'use_magic_file' ] &&
          FileTest.exist?( "/usr/bin/file" ) &&
          FileTest.exist?( filename ) &&
          /\blisting\.txt\b/ !~ filename
        )
          file_type = `/usr/bin/file -L #{filename}`
          if file_type !~ /text/ && file_type !~ /empty$/
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
              buffer.go_to_line( line_number, 0 )
            else
              if top_line
                buffer.pitch_view_to( top_line, Buffer::DONT_PITCH_CURSOR, Buffer::DONT_DISPLAY )
              end
              if left_column
                buffer.pan_view_to( left_column, Buffer::DONT_DISPLAY )
              end
              if last_row && last_col
                buffer.cursor_to( last_row, last_col, Buffer::DONT_DISPLAY )
              end
              buffer.display
            end
          end
        end
      end

      buffer
    end
    alias_method :new_file, :open_file

    # Prompts the user for a file to open, then opens it with #open_file .
    # @see #open_file
    def open_file_ask
      prefill = ''

      if buffer_current
        if buffer_current.current_line =~ %r#(/\w+)+/\w+\.\w+#
          prefill = $&
        elsif buffer_current.name
          prefill = File.expand_path( File.dirname( buffer_current.name ) ) + "/"
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
      file = get_user_input(
        "Filename: ",
        history: @rlh_files,
        initial_text: prefill,
        &finder_block
      )

      if file
        open_file file
        update_status_line
        update_context_line
      end
    end

    # Opens all files within a directory whose contents match a regular
    # expression.
    # @param regexp [String]
    #   The regular expression used to match against.  If nil, the user is
    #   prompted for a value.
    # @param search_root [String]
    #   The directory under which to recursively search for matches.  If nil,
    #   the user is prompted for a value.
    def open_matching_files( regexp = nil, search_root = nil )
      regexp ||= get_user_input( "Regexp: ", history: @rlh_search )
      return  if regexp.nil?

      if buffer_current.current_line =~ %r{\w*/[/\w.]+}
        prefill = $&
      else
        prefill = File.expand_path( File.dirname( buffer_current.name ) ) + "/"
      end
      search_root ||= get_user_input( "Search within: ", history: @rlh_files, initial_text: prefill )
      return  if search_root.nil?

      files = `egrep -rl '#{regexp.gsub( /'/, "'\\\\''" )}' #{search_root}/*`.split( /\n/ )
      if files.any?
        if files.size > 5
            choice = get_choice( "Open #{files.size} files?", [ CHOICE_YES, CHOICE_NO ] )
            return  if choice == CHOICE_NO
        end
        files.each do |f|
          open_file f
        end
        find 'down', CASE_SENSITIVE, regexp
      end
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
          buffer_current.name,
          'read_only' => false,
          'revert' => FORCE_REVERT,
          'cursor' => {
            'row' => buffer_current.last_row,
            'col' => buffer_current.last_col
          }
        )
      end
    end

    # Saves a buffer, then runs the :after_save hook on it.
    # @param [Buffer] buffer
    #   The buffer to save.  If nil, defaults to the current buffer.
    def save_file( buffer = buffer_current )
      buffer.save
      run_hook_procs( :after_save, buffer )
    end

    def save_file_as
      if buffer_current && buffer_current.name
        path = File.expand_path( File.dirname( buffer_current.name ) ) + "/"
        file = get_user_input( "Filename: ", history: @rlh_files, initial_text: path )
      else
        file = get_user_input( "Filename: ", history: @rlh_files )
      end
      if file
        old_name = buffer_current.name
        if buffer_current.save( file, PROMPT_OVERWRITE )
          @buffers.delete old_name
          @buffers[ buffer_current.name ] = buffer_current
          save_session
        end
      end
    end

    # Sets the type (language) of the current buffer.
    # @param [String] type_
    #   The type to set the current buffer to.
    #   If nil, the user is prompted for a value.
    def set_buffer_type( type_ = nil )
      type = type_ || get_user_input( "Content type: " )

      if type
        if buffer_current.set_type( type )
          update_status_line
          update_context_line
        end
      end
    end

    # If read_only is nil, the read_only state of the current buffer is toggled.
    # Otherwise, the read_only state of the current buffer is set to read_only.
    def set_read_only( read_only = nil )
      if read_only
        buffer_current.read_only = read_only
      else
        buffer_current.read_only = ( ! buffer_current.read_only )
      end
      update_status_line
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
      switch_to_buffer_number( buffer_to_number( buffer_current ) + 1 )
    end

    def switch_to_previous_buffer
      switch_to_buffer_number( buffer_to_number( buffer_current ) - 1 )
    end

  end
end
