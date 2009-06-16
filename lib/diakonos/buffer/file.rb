module Diakonos

  class Buffer

    def save( filename = nil, prompt_overwrite = DONT_PROMPT_OVERWRITE )
      if filename
        name = File.expand_path( filename )
      else
        name = @name
      end

      if @read_only and FileTest.exists?( @name ) and FileTest.exists?( name ) and ( File.stat( @name ).ino == File.stat( name ).ino )
        @diakonos.set_iline "#{name} cannot be saved since it is read-only."
      else
        @read_only = false
        if name.nil?
          @diakonos.save_file_as
        else
          proceed = true

          if prompt_overwrite and FileTest.exists? name
            proceed = false
            choice = @diakonos.get_choice(
              "Overwrite existing '#{name}'?",
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

          if file_modified?
            proceed = ! @diakonos.revert( "File has been altered externally.  Load on-disk version?" )
          end

          if proceed
            save_copy name
            @name = name
            @last_modification_check = File.mtime( @name )
            saved = true

            if @name =~ /#{@diakonos.diakonos_home}\/.*\.conf/
              @diakonos.load_configuration
              @diakonos.initialize_display
            end

            @modified = false

            display
            @diakonos.update_status_line
          end
        end
      end

      saved
    end

    # Returns true on successful write.
    def save_copy( filename )
      return false if filename.nil?

      name = File.expand_path( filename )

      File.open( name, "w" ) do |f|
        @lines[ 0..-2 ].each do |line|
          if @settings[ 'strip_trailing_whitespace_on_save' ]
            line.rstrip!
          end
          f.puts line
        end

        line = @lines[ -1 ]
        if @settings[ 'strip_trailing_whitespace_on_save' ]
          line.rstrip!
        end
        if line != ""
          # No final newline character
          f.print line
          f.print "\n" if @settings[ "eof_newline" ]
        end

        if @settings[ 'strip_trailing_whitespace_on_save' ]
          if @last_col > @lines[ @last_row ].size
            cursor_to @last_row, @lines[ @last_row ].size
          end
        end
      end
    end

    # Check if the file which is being edited has been modified since
    # the last time we checked it; return true if so, false otherwise.
    def file_modified?
      modified = false

      if @name
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

      modified
    end

    # Compares MD5 sums of buffer and actual file on disk.
    # Returns true if there is no file on disk.
    def file_different?
      if @name
        Digest::MD5.hexdigest(
          @lines.join( "\n" )
        ) != Digest::MD5.hexdigest(
          File.read( @name )
        )
      else
        true
      end
    end

    def set_modified( do_display = DO_DISPLAY, use_md5 = DONT_USE_MD5 )
      if @read_only
        @diakonos.set_iline "Warning: Modifying a read-only file."
      end

      if ! @modified
        fmod = file_modified?
      end

      if fmod
        reverted = @diakonos.revert( "File has been altered externally.  Load on-disk version?" )
      end

      @modified = use_md5 ? file_different? : true
      if ! reverted
        clear_matches
        if do_display
          @diakonos.update_status_line
          display
        end
      end
    end

  end

end