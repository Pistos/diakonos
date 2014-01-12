module Diakonos
  class Session
    attr_reader :filename, :settings, :name, :dir, :buffers, :readline_histories
    attr_accessor :buffer_current

    def initialize(filepath, data = nil)
      if data.nil?
        @filename = File.expand_path(filepath)
        @settings = Hash.new

        basename = File.basename(filepath)
        if ! Session.pid_session?(filepath)
          @name = basename
        end

        @buffers = []
        @buffer_current = 1
        self.dir = Dir.getwd
      else
        @filename = data['filename']
        @settings = data['settings']
        @name = data['name']
        @buffers = data['buffers']
        @buffer_current = data['buffer_current'] || 1
        self.dir = data['dir']
      end
    end

    def to_yaml
      {
        'filename' => @filename,
        'settings' => @settings,
        'name' => @name,
        'buffer_current' => @buffer_current,
        'dir' => @dir,
        'buffers' => @buffers,
        'readline_histories' => @readline_histories
      }.to_yaml
    end

    def set_buffers(buffers)
      @buffers = buffers.reject { |buffer|
        buffer.name.nil?
      }.collect { |buffer|
        {
          'filepath' => buffer.name,
          'read_only' => buffer.read_only,
          'cursor'   => {
            'row' => buffer.last_row,
            'col' => buffer.last_col,
          },
          'display'  => {
            'top_line'    => buffer.top_line,
            'left_column' => buffer.left_column
          },
          'last_search_regexps' => buffer.last_search_regexps.map { |r| r.to_s },
        }
      }.compact
    end

    def set_readline_histories(rlh_general, rlh_files, rlh_search, rlh_shell, rlh_help, rlh_sessions)
      @readline_histories = {
        'general'  => rlh_general,
        'files'    => rlh_files,
        'search'   => rlh_search,
        'shell'    => rlh_shell,
        'help'     => rlh_help,
        'sessions' => rlh_sessions,
      }
    end

    def dir=(new_dir)
      @dir = new_dir
      Dir.chdir new_dir
    end

    # @return [Session] The Session created from the YAML data in the specified file
    #   or nil on failure to load
    def self.from_yaml_file(yaml_filename)
      return nil  if ! File.exist?(yaml_filename)
      session = nil

      File.open(yaml_filename) do |f|
        loaded = YAML::load(f) or break

        if(
          loaded[ 'filename' ] &&
          loaded[ 'settings' ] &&
          loaded[ 'settings' ].respond_to?( :values ) &&
          loaded.has_key?( 'name' ) &&
          (
            loaded[ 'files' ] &&
            loaded[ 'files' ].respond_to?( :each ) ||
            loaded[ 'buffers' ] &&
            loaded[ 'buffers' ].respond_to?( :each )
          )
        )
          # Convert old sessions
          if loaded[ 'files' ]
            loaded[ 'buffers' ] = loaded[ 'files' ].map { |f|
              Session.file_hash_for f
            }
            loaded.delete 'files'
          end

          session = Session.new(loaded['filename'], loaded)
        end
      end

      session
    end

    def self.pid_session?(path)
      %r{/\d+$} === path
    end

    def self.file_hash_for(filepath)
      filepath, line_number = ::Diakonos.parse_filename_and_line_number(filepath)
      {
        'filepath'  => filepath,
        'read_only' => false,
        'cursor'    => {
          'row' => line_number || 0,
          'col' => 0,
        },
        'display'   => {
          'top_line'    => 0,
          'left_column' => 0
        },
      }
    end

  end

  class Diakonos
    attr_reader :session

    def initialize_session
      @session_dir = "#{@diakonos_home}/sessions"
      mkdir @session_dir
      @session = Session.new("#{@session_dir}/#{Process.pid}")
    end

    def load_session( session_file )
      cleanup_session
      @session = Session.from_yaml_file(session_file)
      if @session
        @files.concat @session.buffers
        rlh = @session.readline_histories
        if rlh
          @rlh_general  = rlh['general'] || @rlh_general
          @rlh_files    = rlh['files'] || @rlh_files
          @rlh_search   = rlh['search'] || @rlh_search
          @rlh_shell    = rlh['shell'] || @rlh_shell
          @rlh_help     = rlh['help'] || @rlh_help
          @rlh_sessions = rlh['sessions'] || @rlh_sessions
        end
        merge_session_settings
      end
    end

    def save_session( session_file = @session.filename )
      return  if session_file.nil?
      return  if @testing && Session.pid_session?(session_file)

      @session.set_buffers(@buffers)
      @session.set_readline_histories(@rlh_general, @rlh_files, @rlh_search, @rlh_shell, @rlh_help, @rlh_sessions)

      File.open( session_file, 'w' ) do |f|
        f.puts @session.to_yaml
      end
    end

    def session_filepath_for( session_id )
      if session_id && session_id !~ %r{/}
        "#{@session_dir}/#{session_id}"
      else
        session_id
      end
    end

    def session_startup
      @stale_session_files = []

      if @session_to_load
        pid_session = @session
        @session = nil
        session_path = session_filepath_for( @session_to_load )
        load_session session_path
        if ! @session
          @session = Session.new(session_path)
        end
      else
        session_files = Dir[ "#{@session_dir}/*" ].grep( %r{/\d+$} )
        session_files.each do |sf|
          pid = sf[ %r{/(\d+)$}, 1 ].to_i

          # Check if the process is still alive
          begin
            Process.kill 0, pid
          rescue Errno::ESRCH, Errno::EPERM
            if Session.pid_session?(sf)
              @stale_session_files << sf
            end
          end
        end
      end
    end

    # We have to do this separately and later (as opposed to inside #session_startup)
    # because we have to wait for the display to get initialized in order to
    # prompt the user for input, etc.
    def handle_stale_session_files
      return  if @testing
      return  if @stale_session_files.empty?

      session_buffers = []
      @stale_session_files.each_with_index do |session_file,index|
        session_buffers << open_file( session_file )

        choice = get_choice(
          "#{@stale_session_files.size} unclosed session(s) found.  Open the above files?  (session #{index+1} of #{@stale_session_files.size})",
          [ CHOICE_YES, CHOICE_NO, CHOICE_DELETE ],
          index > 0 ?  CHOICE_NO : nil
        )

        case choice
        when CHOICE_YES
          load_session session_file
          if @session
            File.delete session_file
            break
          end
        when CHOICE_DELETE
          File.delete session_file
        end
      end

      if session_buffers.empty? && @files.empty? && @settings[ 'session.default_session' ]
        session_file = session_filepath_for( @settings[ 'session.default_session' ] )
        if File.exist? session_file
          load_session session_file
        end
      end

      session_buffers.each do |buffer|
        close_buffer buffer
      end
    end

    def cleanup_session
      if @session && Session.pid_session?(@session.filename) && File.exists?(@session.filename)
        File.delete @session.filename
      end
    end
  end
end
