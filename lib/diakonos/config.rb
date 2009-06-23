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
    attr_reader :token_regexps, :close_token_regexps, :token_formats, :diakonos_conf, :column_markers

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
      rescue SocketError, OpenURI::HTTPError => e
        $stderr.puts "Failed to fetch from #{location}."
      end

      found
    end

    def load_configuration
      # Set defaults first

      conf_dir = INSTALL_SETTINGS[ :conf_dir ]
      @global_diakonos_conf = "#{conf_dir}/diakonos.conf"
      @diakonos_conf = @config_filename || "#{@diakonos_home}/diakonos.conf"

      if ! FileTest.exists?( @diakonos_conf )
        if FileTest.exists?( @global_diakonos_conf )
          puts "No personal configuration file found."
          puts "Would you like to copy the system-wide configuration file (#{@global_diakonos_conf}) to use"
          $stdout.print "as a basis for your personal configuration (recommended)? (y/n)"; $stdout.flush
          answer = $stdin.gets
          if answer =~ /^y/i
            require 'fileutils'
            FileUtils.cp @global_diakonos_conf, @diakonos_conf
          end
        else
          if @testing
            File.open( @diakonos_conf, 'w' ) do |f|
              f.puts File.read( './diakonos.conf' )
            end
          else
            puts "diakonos.conf not found in any of:"
            puts "  #{conf_dir}"
            puts "  #{@diakonos_home}"
            puts "At least one configuration file must exist."
            $stdout.print "Would you like to download one right now from the Diakonos repository? (y/n)"; $stdout.flush
            answer = $stdin.gets

            case answer
            when /^y/i
              if not fetch_conf
                fetch_conf 'master'
              end
            end
          end

          if not FileTest.exists?( @diakonos_conf )
            puts "Terminating due to lack of configuration file."
            exit 1
          end
        end
      end

      @logfilename         = @diakonos_home + "/diakonos.log"
      @keychains           = Hash.new
      @token_regexps       = Hash.new { |h,k| h[ k ] = Hash.new }
      @close_token_regexps = Hash.new { |h,k| h[ k ] = Hash.new }
      @token_formats       = Hash.new { |h,k| h[ k ] = Hash.new }
      @column_markers      = Hash.new { |h,k| h[ k ] = Hash.new }
      @indenters           = Hash.new
      @indenters_next_line  = Hash.new
      @unindenters         = Hash.new
      @filemasks           = Hash.new
      @bangmasks           = Hash.new
      @closers             = Hash.new

      @settings = Hash.new
      @setting_strings = Hash.new
      # Setup some defaults
      @settings[ "context.format" ] = Curses::A_REVERSE

      @keychains[ Curses::KEY_RESIZE ] = [ "redraw", nil ]
      @keychains[ RESIZE2 ] = [ "redraw", nil ]

      @colour_pairs = Array.new

      begin
        parse_configuration_file @global_diakonos_conf
        parse_configuration_file @diakonos_conf

        # Session settings override config file settings.

        @session[ 'settings' ].each do |key,value|
          @settings[ key ] = value
        end

        case @settings[ 'clipboard.external' ]
        when 'klipper'
          @clipboard = ClipboardKlipper.new
        when 'xclip'
          @clipboard = ClipboardXClip.new
        else
          @clipboard = Clipboard.new( @settings[ "max_clips" ] )
        end
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

    def get_token_regexp( hash, arg, match )
      language = match[ 1 ]
      token_class = match[ 2 ]
      case_insensitive = ( match[ 3 ] != nil )
      hash[ language ] = ( hash[ language ] or Hash.new )
      if case_insensitive
        hash[ language ][ token_class ] = Regexp.new( arg, Regexp::IGNORECASE )
      else
        hash[ language ][ token_class ] = Regexp.new arg
      end
    end

    def parse_configuration_file( filename )
      return  if ! FileTest.exists? filename

      IO.foreach( filename ) do |line|
        line.chomp!
        # Skip comments
        next  if line[ 0 ] == ?#

        if line =~ /^\s*(\S+)\s*=\s*(\S+)\s*$/
          # Inheritance
          command, arg = $1, @setting_strings[ $2 ]
        end

        if arg.nil?
          command, arg = line.split( /\s+/, 2 )
          next  if command.nil?
        end
        command = command.downcase

        @setting_strings[ command ] = arg

        case command
        when "include"
          parse_configuration_file File.expand_path( arg )
        when 'load_extension'
          @extensions.load( arg ).each do |conf_file|
            parse_configuration_file conf_file
          end
        when "key"
          if arg
            if /  / === arg
              keystrings, function_and_args = arg.split( / {2,}/, 2 )
            else
              keystrings, function_and_args = arg.split( /;/, 2 )
            end
            keystrokes = Array.new
            keystrings.split( /\s+/ ).each do |ks_str|
              codes = Keying.keycodes_for( ks_str )
              if codes.empty?
                puts "Unknown keystring: #{ks_str}"
              else
                keystrokes.concat codes
              end
            end
            if function_and_args.nil?
              @keychains.delete_key_path( keystrokes )
            else
              function, function_args = function_and_args.split( /\s+/, 2 )
              @keychains.set_key_path(
                keystrokes,
                [ function, function_args ]
              )
            end
          end
        when /^lang\.(.+?)\.tokens\.([^.]+)(\.case_insensitive)?$/, /^lang\.(.+?)\.tokens\.([^.]+)\.open(\.case_insensitive)?$/
          get_token_regexp( @token_regexps, arg, Regexp.last_match )
        when /^lang\.(.+?)\.tokens\.([^.]+)\.close(\.case_insensitive)?$/
          get_token_regexp( @close_token_regexps, arg, Regexp.last_match )
        when /^lang\.(.+?)\.tokens\.(.+?)\.format$/
          language = $1
          token_class = $2
          @token_formats[ language ][ token_class ] = Display.to_formatting( arg )
        when /^lang\.(.+?)\.format\..+$/
          @settings[ command ] = Display.to_formatting( arg )
        when /^colou?r$/
          number, fg, bg = arg.split( /\s+/ )
          number = number.to_i
          fg = Display.to_colour_constant( fg )
          bg = Display.to_colour_constant( bg )
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
        when /^lang\.(.+?)\.indent\.indenters_next_line(\.case_insensitive)?$/
          case_insensitive = ( $2 != nil )
          if case_insensitive
            @indenters_next_line[ $1 ] = Regexp.new( arg, Regexp::IGNORECASE )
          else
            @indenters_next_line[ $1 ] = Regexp.new arg
          end
        when /^lang\.(.+?)\.indent\.unindenters(\.case_insensitive)?$/
          case_insensitive = ( $2 != nil )
          if case_insensitive
            @unindenters[ $1 ] = Regexp.new( arg, Regexp::IGNORECASE )
          else
            @unindenters[ $1 ] = Regexp.new arg
          end
        when /^lang\.(.+?)\.indent\.(?:preventers|ignore|not_indented)(\.case_insensitive)?$/,
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
              show_exception(
                e,
                [ "Failed to process Proc for #{command}.", ]
              )
            end
          end
        when "context.visible", "context.combined", "eof_newline", "view.nonfilelines.visible",
            /^lang\.(.+?)\.indent\.(?:auto|roundup|using_tabs|closers)$/,
            "found_cursor_start", "convert_tabs", 'delete_newline_on_delete_to_eol',
            'suppress_welcome', 'strip_trailing_whitespace_on_save',
            'find.return_on_abort', 'fuzzy_file_find', 'view.line_numbers',
            'find.show_context_after', 'view.pairs.highlight', 'auto_read_only'
          @settings[ command ] = arg.to_b
        when "context.format", "context.separator.format", "status.format", 'view.line_numbers.format'
          @settings[ command ] = Display.to_formatting( arg )
        when /view\.column_markers\.(.+?)\.format/
          @column_markers[ $1 ][ :format ] = Display.to_formatting( arg )
        when "logfile"
          @logfilename = File.expand_path( arg )
        when "context.separator", "status.left", "status.right", "status.filler",
            "status.modified_str", "status.unnamed_str", "status.selecting_str",
            "status.read_only_str", /^lang\..+?\.indent\.ignore\.charset$/,
            /^lang\.(.+?)\.tokens\.([^.]+)\.change_to$/,
            /^lang\.(.+?)\.column_delimiters$/,
            "view.nonfilelines.character",
            'interaction.blink_string', 'diff_command', 'session.default_session',
            'clipboard.external'
          @settings[ command ] = arg
        when /^lang\..+?\.comment_(?:close_)?string$/, 'view.line_numbers.number_format'
          @settings[ command ] = arg.gsub( /^["']|["']$/, '' )
        when "status.vars"
          @settings[ command ] = arg.split( /\s+/ )
        when /^lang\.(.+?)\.indent\.size$/, /^lang\.(.+?)\.(?:tabsize|wrap_margin)$/,
            "context.max_levels", "context.max_segment_width", "max_clips", "max_undo_lines",
            "view.margin.x", "view.margin.y", "view.scroll_amount", "view.lookback", 'grep.context',
            'view.line_numbers.width'
          @settings[ command ] = arg.to_i
        when "view.jump.x", "view.jump.y"
          @settings[ command ] = [ arg.to_i, 1 ].max
        when /view\.column_markers\.(.+?)\.column/
          @column_markers[ $1 ][ :column ] = [ arg.to_i, 1 ].max
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

  end
end
