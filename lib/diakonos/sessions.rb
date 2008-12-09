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
  end
end