module Diakonos

  BOL_ZERO           = 0
  BOL_FIRST_CHAR     = 1
  BOL_ALT_ZERO       = 2
  BOL_ALT_FIRST_CHAR = 3

  EOL_END           = 0
  EOL_LAST_CHAR     = 1
  EOL_ALT_END       = 2
  EOL_ALT_LAST_CHAR = 3

  class Diakonos
    attr_reader :token_regexps, :close_token_regexps, :token_formats, :diakonos_conf

    def fetch_conf( location = "v#{VERSION}" )
      require 'open-uri'
      found = false
      puts "Fetching configuration from #{location}..."

      begin
        open( "http://github.com/Pistos/diakonos/tree/#{location}/diakonos.conf?raw=true" ) do |http|
          text = http.read
          if text =~ /key/ and text =~ /colour/ and text =~ /lang/
            found = true
            File.open( @diakonos_conf, 'w' ) do |f|
              f.puts text
            end
          end
        end
      rescue OpenURI::HTTPError => e
        $stderr.puts "Failed to fetch from #{location}."
      end

      found
    end

    def loadConfiguration
      # Set defaults first

      existent = 0
      conf_dirs = [
        '/usr/local/etc/diakonos.conf',
        '/usr/etc/diakonos.conf',
        '/etc/diakonos.conf',
        '/usr/local/share/diakonos/diakonos.conf',
        '/usr/share/diakonos/diakonos.conf'
      ]

      conf_dirs.each do |conf_dir|
        @global_diakonos_conf = conf_dir
        if FileTest.exists? @global_diakonos_conf
          existent += 1
          break
        end
      end

      @diakonos_conf = ( @config_filename or ( @diakonos_home + '/diakonos.conf' ) )
      existent += 1 if FileTest.exists? @diakonos_conf

      if existent < 1
        if @testing
          File.open( @diakonos_conf, 'w' ) do |f|
            f.puts File.read( './diakonos.conf' )
          end
        else
          puts "diakonos.conf not found in any of:"
          conf_dirs.each do |conf_dir|
            puts "   #{conf_dir}"
          end
          puts "   ~/.diakonos/"
          puts "At least one configuration file must exist."
          $stdout.puts "Would you like to download one right now from the Diakonos repository? (y/n)"; $stdout.flush
          answer = $stdin.gets

          case answer
          when /^y/i
            if not fetch_conf
              fetch_conf 'master'
            end
          end
        end

        if not FileTest.exists?( @diakonos_conf )
          puts "Terminating..."
          exit 1
        end
      end

      @logfilename = @diakonos_home + "/diakonos.log"
      @keychains           = Hash.new
      @token_regexps       = Hash.new
      @close_token_regexps = Hash.new
      @token_formats       = Hash.new
      @indenters           = Hash.new
      @unindenters         = Hash.new
      @filemasks           = Hash.new
      @bangmasks           = Hash.new
      @closers             = Hash.new

      @settings = Hash.new
      # Setup some defaults
      @settings[ "context.format" ] = Curses::A_REVERSE

      @keychains[ Curses::KEY_RESIZE ] = [ "redraw", nil ]
      @keychains[ RESIZE2 ] = [ "redraw", nil ]

      @colour_pairs = Array.new

      begin
        parseConfigurationFile( @global_diakonos_conf )
        parseConfigurationFile( @diakonos_conf )

        # Session settings override config file settings.

        @session[ 'settings' ].each do |key,value|
          @settings[ key ] = value
        end

        @clipboard = Clipboard.new @settings[ "max_clips" ]
        @log = File.open( @logfilename, "a" )

        if @buffers
          @buffers.each_value do |buffer|
            buffer.configure
          end
        end
      rescue Errno::ENOENT
        # No config file found or readable
      end
    end

    def parseConfigurationFile( filename )
      return if not FileTest.exists? filename

      lines = IO.readlines( filename ).collect { |l| l.chomp }
      lines.each do |line|
        # Skip comments
        next if line[ 0 ] == ?#

        command, arg = line.split( /\s+/, 2 )
        next if command.nil?
        command = command.downcase
        case command
        when "include"
          parseConfigurationFile arg.subHome
        when "key"
          if arg
            if /  / === arg
              keystrings, function_and_args = arg.split( / {2,}/, 2 )
            else
              keystrings, function_and_args = arg.split( /;/, 2 )
            end
            keystrokes = Array.new
            keystrings.split( /\s+/ ).each do |ks_str|
              code = ks_str.keyCode
              if code
                keystrokes.concat code
              else
                puts "unknown keystring: #{ks_str}"
              end
            end
            if function_and_args.nil?
              @keychains.deleteKeyPath( keystrokes )
            else
              function, function_args = function_and_args.split( /\s+/, 2 )
              @keychains.setKeyPath(
                keystrokes,
                [ function, function_args ]
              )
            end
          end
        when /^lang\.(.+?)\.tokens\.([^.]+)(\.case_insensitive)?$/
          getTokenRegexp( @token_regexps, arg, Regexp.last_match )
        when /^lang\.(.+?)\.tokens\.([^.]+)\.open(\.case_insensitive)?$/
          getTokenRegexp( @token_regexps, arg, Regexp.last_match )
        when /^lang\.(.+?)\.tokens\.([^.]+)\.close(\.case_insensitive)?$/
          getTokenRegexp( @close_token_regexps, arg, Regexp.last_match )
        when /^lang\.(.+?)\.tokens\.(.+?)\.format$/
          language = $1
          token_class = $2
          @token_formats[ language ] = ( @token_formats[ language ] or Hash.new )
          @token_formats[ language ][ token_class ] = arg.toFormatting
        when /^lang\.(.+?)\.format\..+$/
          @settings[ command ] = arg.toFormatting
        when /^colou?r$/
          number, fg, bg = arg.split( /\s+/ )
          number = number.to_i
          fg = fg.toColourConstant
          bg = bg.toColourConstant
          @colour_pairs << {
            :number => number,
            :fg => fg,
            :bg => bg
          }
        when /^lang\.(.+?)\.indent\.indenters(\.case_insensitive)?$/
          case_insensitive = ( $2 != nil )
          if case_insensitive
            @indenters[ $1 ] = Regexp.new( arg, Regexp::IGNORECASE )
          else
            @indenters[ $1 ] = Regexp.new arg
          end
        when /^lang\.(.+?)\.indent\.unindenters(\.case_insensitive)?$/
          case_insensitive = ( $2 != nil )
          if case_insensitive
            @unindenters[ $1 ] = Regexp.new( arg, Regexp::IGNORECASE )
          else
            @unindenters[ $1 ] = Regexp.new arg
          end
        when /^lang\.(.+?)\.indent\.preventers(\.case_insensitive)?$/,
          /^lang\.(.+?)\.indent\.ignore(\.case_insensitive)?$/,
          /^lang\.(.+?)\.context\.ignore(\.case_insensitive)?$/
          case_insensitive = ( $2 != nil )
          if case_insensitive
            @settings[ command ] = Regexp.new( arg, Regexp::IGNORECASE )
          else
            @settings[ command ] = Regexp.new arg
          end
        when /^lang\.(.+?)\.filemask$/
          @filemasks[ $1 ] = Regexp.new arg
        when /^lang\.(.+?)\.bangmask$/
          @bangmasks[ $1 ] = Regexp.new arg
        when /^lang\.(.+?)\.closers\.(.+?)\.(.+?)$/
          @closers[ $1 ] ||= Hash.new
          @closers[ $1 ][ $2 ] ||= Hash.new
          @closers[ $1 ][ $2 ][ $3.to_sym ] = case $3
        when 'regexp'
          Regexp.new arg
        when 'closer'
          begin
            eval( "Proc.new " + arg )
          rescue Exception => e
            showException(
              e,
              [
                "Failed to process Proc for #{command}.",
              ]
            )
          end
        end
        when "context.visible", "context.combined", "eof_newline", "view.nonfilelines.visible",
          /^lang\.(.+?)\.indent\.(?:auto|roundup|using_tabs|closers)$/,
          "found_cursor_start", "convert_tabs", 'delete_newline_on_delete_to_eol',
          'suppress_welcome', 'strip_trailing_whitespace_on_save',
          'find.return_on_abort', 'fuzzy_file_find', 'view.line_numbers'
          @settings[ command ] = arg.to_b
        when "context.format", "context.separator.format", "status.format"
          @settings[ command ] = arg.toFormatting
        when "logfile"
          @logfilename = arg.subHome
        when "context.separator", "status.left", "status.right", "status.filler",
          "status.modified_str", "status.unnamed_str", "status.selecting_str",
          "status.read_only_str", /^lang\..+?\.indent\.ignore\.charset$/,
          /^lang\.(.+?)\.tokens\.([^.]+)\.change_to$/,
          /^lang\.(.+?)\.column_delimiters$/,
          "view.nonfilelines.character",
          'interaction.blink_string', 'diff_command', 'session.default_session'
          @settings[ command ] = arg
        when /^lang\..+?\.comment_(?:close_)?string$/
          @settings[ command ] = arg.gsub( /^["']|["']$/, '' )
        when "status.vars"
          @settings[ command ] = arg.split( /\s+/ )
        when /^lang\.(.+?)\.indent\.size$/, /^lang\.(.+?)\.(?:tabsize|wrap_margin)$/
          @settings[ command ] = arg.to_i
        when "context.max_levels", "context.max_segment_width", "max_clips", "max_undo_lines",
          "view.margin.x", "view.margin.y", "view.scroll_amount", "view.lookback", 'grep.context'
          @settings[ command ] = arg.to_i
        when "view.jump.x", "view.jump.y"
          value = arg.to_i
          if value < 1
            value = 1
          end
          @settings[ command ] = value
        when "bol_behaviour", "bol_behavior"
          case arg.downcase
          when "zero"
            @settings[ "bol_behaviour" ] = BOL_ZERO
          when "first-char"
            @settings[ "bol_behaviour" ] = BOL_FIRST_CHAR
          when "alternating-zero"
            @settings[ "bol_behaviour" ] = BOL_ALT_ZERO
          else # default
            @settings[ "bol_behaviour" ] = BOL_ALT_FIRST_CHAR
          end
        when "eol_behaviour", "eol_behavior"
          case arg.downcase
          when "end"
            @settings[ "eol_behaviour" ] = EOL_END
          when "last-char"
            @settings[ "eol_behaviour" ] = EOL_LAST_CHAR
          when "alternating-last-char"
            @settings[ "eol_behaviour" ] = EOL_ALT_FIRST_CHAR
          else # default
            @settings[ "eol_behaviour" ] = EOL_ALT_END
          end
        when "context.delay", 'interaction.blink_duration', 'interaction.choice_delay'
          @settings[ command ] = arg.to_f
        end
      end
    end
    protected :parseConfigurationFile

  end
end