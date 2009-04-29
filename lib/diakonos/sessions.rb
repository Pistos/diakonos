module Diakonos
  class Diakonos

    def new_session( filepath )
      basename = File.basename( filepath )
      if not pid_session?( filepath )
        name = basename
      end
      @session = {
        'filename' => File.expand_path( filepath ),
        'settings' => Hash.new,
        'name' => name,
        'files' => [],
        'dir' => Dir.getwd,
      }
    end

    def initialize_sessions
      @session_dir = "#{@diakonos_home}/sessions"
      mkdir @session_dir
      new_session "#{@session_dir}/#{Process.pid}"
    end

    def load_session_data( filename )
      return if not File.exist? filename
      File.open( filename ) do |f|
        loaded = YAML::load( f )
        if loaded
          if(
            loaded[ 'filename' ] and
            loaded[ 'settings' ] and
            loaded[ 'settings' ].respond_to?( :values ) and
            loaded[ 'name' ] and
            loaded[ 'files' ] and
            loaded[ 'files' ].respond_to?( :each )
          )
            @session = loaded
          end
        end
      end
    end

    def save_session( session_file = @session[ 'filename' ] )
      return if session_file.nil?
      @session[ 'files' ] = @buffers.collect { |filepath,buffer|
        buffer.name ? filepath : nil
      }.compact
      File.open( session_file, 'w' ) do |f|
        f.puts @session.to_yaml
      end
    end

    def session_filepath_for( session_id )
      if session_id and session_id !~ %r{/}
        "#{@session_dir}/#{session_id}"
      else
        session_id
      end
    end

    def pid_session?( path = @session[ 'filename' ] )
      %r{/\d+$} === path
    end

    def session_startup
      if @session_to_load
        pid_session = @session
        @session = nil
        session_path = session_filepath_for( @session_to_load )
        load_session_data session_path
        if @session
          @files.concat @session[ 'files' ]
        else
          new_session session_path
        end
      else
        session_buffers = []

        session_files = Dir[ "#{@session_dir}/*" ].grep( %r{/\d+$} )
        pids = session_files.map { |sf| sf[ %r{/(\d+)$}, 1 ].to_i }
        pids.each do |pid|
          begin
            Process.kill 0, pid
            session_files.reject! { |sf| pid_session? sf }
          rescue Errno::ESRCH, Errno::EPERM
            # Process is no longer alive, so we consider the session stale
          end
        end

        session_files.each_with_index do |session_file,index|
          session_buffers << open_file( session_file )

          choice = get_choice(
            "#{session_files.size} unclosed session(s) found.  Open the above files?  (session #{index+1} of #{session_files.size})",
            [ CHOICE_YES, CHOICE_NO, CHOICE_DELETE ],
            index > 0 ? CHOICE_NO : nil
          )

          case choice
          when CHOICE_YES
            load_session_data session_file
            if @session
              @files.concat @session[ 'files' ]
              File.delete session_file
              break
            end
          when CHOICE_DELETE
            File.delete session_file
          end
        end

        if session_buffers.empty? and @files.empty? and @settings[ 'session.default_session' ]
          session_file = session_filepath_for( @settings[ 'session.default_session' ] )
          if File.exist? session_file
            load_session_data session_file
            if @session
              @files.concat @session[ 'files' ]
            end
          end
        end
      end

      session_buffers
    end

    def increase_grep_context
      current = settings[ 'grep.context' ]
      @session[ 'settings' ][ 'grep.context' ] = current + 1
    end
    def decrease_grep_context
      current = settings[ 'grep.context' ]
      if current > 0
        @session[ 'settings' ][ 'grep.context' ] = current - 1
      end
    end

    def cleanup_session
      if pid_session?
        File.delete @session[ 'filename' ]
      end
    end
  end
end