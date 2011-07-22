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
      if ! @buffers.include?( buffer )
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
        del_buffer = nil
        previous_buffer = nil
        to_switch_to = nil
        switching = false

        # Search the buffer hash for the buffer we want to delete,
        # and mark the one we will switch to after deletion.
        @buffers.each do |b|
          if switching
            to_switch_to = b
            break
          end

          if b == buffer
            del_buffer = b
            switching = true
            next
          end

          previous_buffer = b
        end

        buf = nil
        while(
          @buffer_stack.any? &&
          ! @buffers.include?( buf ) ||
          buf == del_buffer
        ) do
          buf = @buffer_stack.pop
        end
        if @buffers.include?( buf )
          to_switch_to = buf
        end

        if to_switch_to
          switch_to to_switch_to
        elsif previous_buffer
          switch_to previous_buffer
        else
          # No buffers left.  Open a new blank one.
          open_file
        end

        @buffer_closed = del_buffer
        @buffers.delete del_buffer
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
      bullets = ( ('0'..'9').to_a + ('a'..'z').to_a ).map { |s| "#{s}  " }
      buffers_unnamed = @buffers.find_all { |b| b.name.nil? }
      buffers_named = @buffers.find_all { |b| b.name }

      with_list_file do |f|
        if buffers_unnamed.size == 1
          bullet = bullets.shift
          f.puts "#{bullet}(unnamed buffer)"
        else
          buffers_unnamed.each_with_index do |b,i|
            bullet = bullets.shift
            f.puts "#{bullet}(unnamed buffer #{i+1})"
          end
        end

        buffers_named.collect { |b| b.name }.sort.each_with_index do |name, index|
          bullet = bullets.shift
          f.puts "#{bullet}#{name}"
        end
      end
      open_list_buffer
      filename = get_user_input( "Switch to buffer: ", numbered_list: true )
      buffer = buffers_named.find { |b| b.name == filename }
      if buffer
        switch_to buffer
      elsif filename =~ /\(unnamed buffer( \d+)?/
        switch_to( buffers_unnamed[ $1.to_i - 1 ] )
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
    # @option meta [Boolean] 'read_only' (false)
    #   Whether to open the file in read-only (unmodifiable) mode
    # @option meta [Boolean] 'revert' (false)
    #   Whether to skip asking about reverting to on-disk file contents (if different)
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
      if filename
        filename, last_row_ = parse_filename_and_line_number( filename )
        last_row = last_row_ || last_row
        existing_buffer = @buffers.find { |b| b.name == filename }

        if existing_buffer
          do_open = force_revert || ( filename =~ /\.diakonos/ )
          switch_to existing_buffer

          if ! do_open && existing_buffer.file_different?
            show_buffer_file_diff( existing_buffer ) do
              choice = get_choice(
                "Load on-disk version of #{existing_buffer.nice_name}?",
                [ CHOICE_YES, CHOICE_NO ]
              )
              case choice
              when CHOICE_YES
                do_open = true
              when CHOICE_NO
                do_open = false
              end
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
          buffer = Buffer.new(
            'filepath' => filename,
            'read_only' => read_only,
            'display' => {
              'top_line' => top_line,
              'left_column' => left_column,
            },
            'cursor' => {
              'row' => last_row,
              'col' => last_col,
            }
          )
          if existing_buffer
            @buffers[ @buffers.index( existing_buffer ) ] = buffer
          else
            if @settings['open_as_first_buffer']
              @buffers.unshift buffer
            else
              @buffers << buffer
            end
          end
          run_hook_procs( :after_open, buffer )
          save_session
          if switch_to( buffer )
            if last_row
              buffer.cursor_to last_row, last_col || 0
            else
              display_buffer buffer
            end
          end
        end
      elsif existing_buffer && last_row
        existing_buffer.cursor_to last_row, last_col || 0
      end

      buffer || existing_buffer
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
          finder = FuzzyFileFinder.new(
            @session[ 'dir' ],
            @settings['fuzzy_file_find.max_dir_size'] || 8192,
            @fuzzy_ignores
          )
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
        find regexp, direction: 'down', case_sensitive: true
      end
    end

    # Places a buffer at a new position in the array of Buffers
    # after shifting down (index+1) all existing Buffers from that position onwards.
    # @param to [Fixnum] The new 1-based position of the buffer to move
    # @param from [Fixnum] The original 1-based position of the buffer to move.  Default: current buffer
    def renumber_buffer( to, from = nil )
      if to < 1
        raise "Invalid buffer index: #{to.inspect}"
      end
      if from && from < 1
        raise "Invalid buffer index: #{from.inspect}"
      end

      from ||= buffer_to_number( buffer_current )
      from_ = from - 1
      to_   = to - 1
      b = @buffers[from_]
      @buffers.delete_at from_
      @buffers.insert( to_, b )
      @buffers.compact!

      update_status_line
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
      if @buffer_number_last && buffer_number == buffer_to_number(buffer_current)
        buffer_number = @buffer_number_last
      end
      @buffer_number_last = buffer_to_number(buffer_current)
      switch_to @buffers[ buffer_number - 1 ]
    end

    def switch_to_next_buffer
      switch_to_buffer_number( buffer_to_number( buffer_current ) + 1 )
    end

    def switch_to_previous_buffer
      switch_to_buffer_number( buffer_to_number( buffer_current ) - 1 )
    end

  end
end
