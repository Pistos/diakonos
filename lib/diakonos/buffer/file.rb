module Diakonos

  class Buffer

    def save( filename = nil, prompt_overwrite = DONT_PROMPT_OVERWRITE )
      if filename
        name = File.expand_path( filename )
      else
        name = @name
      end

      if @read_only and FileTest.exists?( @name ) and FileTest.exists?( name ) and ( File.stat( @name ).ino == File.stat( name ).ino )
        @diakonos.setILine "#{name} cannot be saved since it is read-only."
      else
        @read_only = false
        if name.nil?
          @diakonos.saveFileAs
        else
          proceed = true

          if prompt_overwrite and FileTest.exists? name
            proceed = false
            choice = @diakonos.getChoice(
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
            saveCopy name
            @name = name
            @last_modification_check = File.mtime( @name )
            saved = true

            if @name =~ /#{@diakonos.diakonos_home}\/.*\.conf/
              @diakonos.loadConfiguration
              @diakonos.initializeDisplay
            end

            @modified = false

            display
            @diakonos.updateStatusLine
          end
        end
      end

      saved
    end

    # Returns true on successful write.
    def saveCopy( filename )
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
            cursorTo @last_row, @lines[ @last_row ].size
          end
        end
      end
    end

  end

end