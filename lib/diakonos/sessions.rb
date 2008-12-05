module Diakonos
  class Diakonos

    def save_session( session_file = @session_file )
      return if session_file.nil?
      File.open( session_file, 'w' ) do |f|
        @buffers.each do |filepath,buffer|
          if buffer.name
            f.puts filepath
          end
        end
      end
    end

    def session_filepath_for( session_id )
      if session_id and not File.exist? session_id
        "#{@session_dir}/#{session_id}"
      else
        session_id
      end
    end

    def pid_session?( path )
      %r{/\d+$} === path
    end
  end
end