module Diakonos
  module Functions

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

    # Returns the buffer of the opened file, or nil.
    # @param meta is metadata containing additional information on how to open
    # the file
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

    def open_matching_files( regexp = nil, search_root = nil )
      regexp ||= get_user_input( "Regexp: ", history: @rlh_search )
      return if regexp.nil?

      if @current_buffer.current_line =~ %r{\w*/[/\w.]+}
        prefill = $&
      else
        prefill = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
      end
      search_root ||= get_user_input( "Search within: ", history: @rlh_files, initial_text: prefill )
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
          'read_only' => false,
          'revert' => FORCE_REVERT,
          'cursor' => {
            'row' => @current_buffer.last_row,
            'col' => @current_buffer.last_col
          }
        )
      end
    end

    def save_file( buffer = @current_buffer )
      buffer.save
      run_hook_procs( :after_save, buffer )
    end

    def save_file_as
      if @current_buffer && @current_buffer.name
        path = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
        file = get_user_input( "Filename: ", history: @rlh_files, initial_text: path )
      else
        file = get_user_input( "Filename: ", history: @rlh_files )
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

  end
end