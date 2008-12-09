module Diakonos
  class Diakonos

    def new_session( filepath )
      @session = {
        'filename' => File.expand_path( filepath ),
        'settings' => Hash.new,
        'name' => File.basename( filepath ),
        'files' => [],
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
        f.puts @session
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
      debugLog "%r{/\d+$} === path  => " + ( %r{/\d+$} === path ).to_s
      %r{/\d+$} === path
    end

    def set_session_name
      name = File.basename( @session[ 'filename' ] )
      if name =~ /\D/
        debugLog "FOO #{name.inspect}"
        @session[ 'name' ] = name
      end
    end
  end
end