#!/usr/bin/env ruby

# == Diakonos
#
# A usable console text editor.
# :title: Diakonos
#
# Author:: Pistos (irc.freenode.net)
# http://purepistos.net/diakonos
# Copyright (c) 2004-2009 Pistos
#
# This software is released under the MIT licence.
# See the LICENCE file included with this program, or
# http://www.opensource.org/licenses/mit-license.php
#
require 'curses'
require 'open3'
require 'thread'
require 'English'
require 'set'
require 'digest/md5'

require 'diakonos/object'
require 'diakonos/enumerable'
require 'diakonos/regexp'
require 'diakonos/sized-array'
require 'diakonos/hash'
require 'diakonos/buffer-hash'
require 'diakonos/array'
require 'diakonos/string'
require 'diakonos/fixnum'
require 'diakonos/bignum'

require 'diakonos/config'
require 'diakonos/functions'
require 'diakonos/help'
require 'diakonos/display'
require 'diakonos/interaction'
require 'diakonos/hooks'
require 'diakonos/keying'
require 'diakonos/logging'
require 'diakonos/list'
require 'diakonos/buffer-management'
require 'diakonos/sessions'

require 'diakonos/keycode'
require 'diakonos/text-mark'
require 'diakonos/bookmark'
require 'diakonos/ctag'
require 'diakonos/finding'
require 'diakonos/buffer'
require 'diakonos/window'
require 'diakonos/clipboard'
require 'diakonos/readline'

require 'vendor/fuzzy_file_finder'

#$profiling = true

#if $profiling
  #require 'ruby-prof'
#end

module Diakonos

  VERSION       = '0.8.7'
  LAST_MODIFIED = 'December 7, 2008'

  DONT_ADJUST_ROW       = false
  ADJUST_ROW            = true
  PROMPT_OVERWRITE      = true
  DONT_PROMPT_OVERWRITE = false
  QUIET                 = true
  NOISY                 = false

  DEFAULT_TAB_SIZE = 8

  FORCE_REVERT = true
  ASK_REVERT   = false

  ASK_REPLACEMENT = true

  CASE_SENSITIVE   = true
  CASE_INSENSITIVE = false

  LANG_TEXT = 'text'

  NUM_LAST_COMMANDS = 2

  class Diakonos

    attr_reader :diakonos_home, :script_dir, :clipboard,
      :list_filename, :hooks, :indenters, :unindenters, :closers,
      :last_commands, :there_was_non_movement, :do_display

    include ::Diakonos::Functions

    def initialize( argv = [] )
      @diakonos_home = ( ( ENV[ 'HOME' ] or '' ) + '/.diakonos' ).subHome
      mkdir @diakonos_home
      @script_dir = "#{@diakonos_home}/scripts"
      mkdir @script_dir
      @session_dir = "#{@diakonos_home}/sessions"
      mkdir @session_dir
      @session_file = "#{@session_dir}/#{Process.pid}"

      init_help

      @debug          = File.new( "#{@diakonos_home}/debug.log", 'w' )
      @list_filename  = @diakonos_home + '/listing.txt'
      @diff_filename  = @diakonos_home + '/text.diff'
      @help_filename  = "#{@help_dir}/about-help.dhf"
      @error_filename = "#{@diakonos_home}/diakonos.err"

      @files = Array.new
      @read_only_files = Array.new
      @config_filename = nil

      parseOptions argv

      @session_settings = Hash.new
      @win_main        = nil
      @win_context     = nil
      @win_status      = nil
      @win_interaction = nil
      @buffers = BufferHash.new

      loadConfiguration

      @quitting    = false
      @untitled_id = 0

      @x = 0
      @y = 0

      @buffer_stack           = Array.new
      @current_buffer         = nil
      @buffer_history         = Array.new
      @buffer_history_pointer = nil
      @bookmarks              = Hash.new
      @macro_history          = nil
      @macro_input_history    = nil
      @macros                 = Hash.new
      @last_commands          = SizedArray.new( NUM_LAST_COMMANDS )
      @playing_macro          = false
      @display_mutex          = Mutex.new
      @display_queue_mutex    = Mutex.new
      @display_queue          = nil
      @do_display             = true
      @iline_mutex            = Mutex.new
      @tag_stack              = Array.new
      @last_search_regexps    = nil
      @iterated_choice        = nil
      @choice_iterations      = 0
      @there_was_non_movement = false
      @status_vars            = Hash.new

      # Readline histories
      @rlh_general  = Array.new
      @rlh_files    = Array.new
      @rlh_search   = Array.new
      @rlh_shell    = Array.new
      @rlh_help     = Array.new
      @rlh_sessions = Array.new

      @hooks = {
        :after_buffer_switch => [],
        :after_open          => [],
        :after_save          => [],
        :after_startup       => [],
      }
    end

    def mkdir( dir )
      if not FileTest.exists? dir
        Dir.mkdir dir
      end
    end

    def parseOptions( argv )
      @post_load_script = ""
      while argv.length > 0
        arg = argv.shift
        case arg
        when '-h', '--help'
          printUsage
          exit 1
        when '-ro'
          filename = argv.shift
          if filename.nil?
            printUsage
            exit 1
          else
            @read_only_files.push filename
          end
        when '-c', '--config'
          @config_filename = argv.shift
          if @config_filename.nil?
            printUsage
            exit 1
          end
        when '-e', '--execute'
          post_load_script = argv.shift
          if post_load_script.nil?
            printUsage
            exit 1
          else
            @post_load_script << "\n#{post_load_script}"
          end
        when '-m', '--open-matching'
          regexp = argv.shift
          files = `egrep -rl '#{regexp}' *`.split( /\n/ )
          if files.any?
            @files.concat files
            script = "\nfind 'down', CASE_SENSITIVE, '#{regexp}'"
            @post_load_script << script
          end
        when '-s', '--load-session'
          session_to_load = argv.shift
          @session_to_load = session_filepath_for( session_to_load )
          if not File.exist? @session_to_load
            File.open( @session_to_load, 'w' ) { |f| }  # Create empty file
            if not File.exist? @session_to_load
              puts "No such session file '#{session_to_load}'; failed to create '#{@session_to_load}'."
              exit
            end
          end
        else
          # a name of a file to open
          @files.push arg
        end
      end
    end
    protected :parseOptions

    def printUsage
      puts "Usage: #{$0} [options] [file] [file...]"
      puts "\t--help\tDisplay usage"
      puts "\t-c <config file>\tLoad this config file instead of ~/.diakonos/diakonos.conf"
      puts "\t-e, --execute <Ruby code>\tExecute Ruby code (such as Diakonos commands) after startup"
      puts "\t-m, --open-matching <regular expression>\tOpen all matching files under current directory"
      puts "\t-ro <file>\tLoad file as read-only"
      puts "\t-s, --load-session <session file>\tLoad a session (file containing a list of file paths)"
    end
    protected :printUsage

    def clearNonMovementFlag
      @there_was_non_movement = false
    end

    # -----------------------------------------------------------------------

    def start
      initializeDisplay

      if ENV[ 'COLORTERM' ] == 'gnome-terminal'
        help_key = 'Shift-F1'
      else
        help_key = 'F1'
      end
      setILine "Diakonos #{VERSION} (#{LAST_MODIFIED})   #{help_key} for help  F12 to configure  Ctrl-Q to quit"

      if @session_to_load
        @session_file = @session_to_load
        files = File.readlines( @session_file ).collect { |filename| filename.strip }
        @files.concat files
      else
        session_buffers = []

        session_files = Dir[ "#{@session_dir}/*" ].grep( %r{/\d+$} )
        pids = session_files.map { |sf| sf[ %r{/(\d+)$}, 1 ].to_i }
        pids.each do |pid|
          begin
            Process.kill 0, pid
            session_files.reject! { |sf| pid_session? sf }
          rescue Errno::ESRCH
            # Process is no longer alive, so we consider the session stale
          end
        end

        session_files.each_with_index do |session_file,index|
          session_buffers << openFile( session_file )

          choice = getChoice(
            "#{session_files.size} unclosed session(s) found.  Open the above files?  (session #{index+1} of #{session_files.size})",
            [ CHOICE_YES, CHOICE_NO, CHOICE_DELETE ]
          )

          case choice
          when CHOICE_YES
            files = File.readlines( session_file ).collect { |filename| filename.strip }
            @files = files
            File.delete session_file
            break
          when CHOICE_DELETE
            File.delete session_file
          end
        end

        if session_buffers.empty? and @files.empty? and @settings[ 'session.default_session' ]
          @session_file = session_filepath_for( @settings[ 'session.default_session' ] )
          if File.exist? @session_file
            files = File.readlines( @session_file ).collect { |filename| filename.strip }
            @files.concat files
          end
        end
      end

      Dir[ "#{@script_dir}/*" ].each do |script|
        begin
          require script
        rescue Exception => e
          showException(
            e,
            [
              "There is a syntax error in the script.",
              "An invalid hook name was used."
            ]
          )
        end
      end
      @hooks.each do |hook_name, hook|
        hook.sort { |a,b| a[ :priority ] <=> b[ :priority ] }
      end

      num_opened = 0
      if @files.length == 0 and @read_only_files.length == 0
        num_opened += 1 if openFile
      else
        @files.each do |file|
          num_opened += 1 if openFile file
        end
        @read_only_files.each do |file|
          num_opened += 1 if openFile( file, Buffer::READ_ONLY )
        end
      end

      if session_buffers
        session_buffers.each do |buffer|
          closeFile buffer
        end
      end

      set_session_name

      if num_opened > 0
        switchToBufferNumber 1

        updateStatusLine
        updateContextLine

        if @post_load_script
          eval @post_load_script
        end

        runHookProcs :after_startup

        if not @settings[ 'suppress_welcome' ]
          openFile "#{@help_dir}/welcome.dhf"
        end

        begin
          # Main keyboard loop.
          while not @quitting
            processKeystroke
            @win_main.refresh
          end
        rescue SignalException => e
          debugLog "Terminated by signal (#{e.message})"
        end

        if @session_file =~ %r{/\d+$}
          File.delete @session_file
        end

        @debug.close
      end
    end

    def showClips
      clip_filename = @diakonos_home + "/clips.txt"
      File.open( clip_filename, "w" ) do |f|
        @clipboard.each do |clip|
          f.puts clip
          f.puts "---------------------------"
        end
      end
      openFile clip_filename
    end

    def getLanguageFromName( name )
      retval = nil
      @filemasks.each do |language,filemask|
        if name =~ filemask
          retval = language
          break
        end
      end
      retval
    end

    def getLanguageFromShaBang( first_line )
      retval = nil
      @bangmasks.each do |language,bangmask|
        if first_line =~ /^#!/ and first_line =~ bangmask
          retval = language
          break
        end
      end
      retval
    end

    def showException( e, probable_causes = [ "Unknown" ] )
      begin
        File.open( @error_filename, "w" ) do |f|
          f.puts "Diakonos Error:"
          f.puts
          f.puts "#{e.class}: #{e.message}"
          f.puts
          f.puts "Probable Causes:"
          f.puts
          probable_causes.each do |pc|
            f.puts "- #{pc}"
          end
          f.puts
          f.puts "----------------------------------------------------"
          f.puts "If you can reproduce this error, please report it at"
          f.puts "http://linis.purepistos.net/ticket/list/Diakonos !"
          f.puts "----------------------------------------------------"
          f.puts e.backtrace
        end
        openFile( @error_filename )
      rescue Exception => e2
        debugLog "EXCEPTION: #{e.message}"
        debugLog "\t#{e.backtrace}"
      end
    end

    def subShellVariables( string )
      return nil if string.nil?

      retval = string
      retval = retval.subHome

      # Current buffer filename
      retval.gsub!( /\$f/, ( $1 or "" ) + ( @current_buffer.name or "" ) )

      # space-separated list of all buffer filenames
      name_array = Array.new
      @buffers.each_value do |b|
        name_array.push b.name
      end
      retval.gsub!( /\$F/, ( $1 or "" ) + ( name_array.join(' ') or "" ) )

      # Get user input, sub it in
      if retval =~ /\$i/
        user_input = getUserInput( "Argument: ", @rlh_shell )
        retval.gsub!( /\$i/, user_input )
      end

      # Current clipboard text
      if retval =~ /\$c/
        clip_filename = @diakonos_home + "/clip.txt"
        File.open( clip_filename, "w" ) do |clipfile|
          if @clipboard.clip
            clipfile.puts( @clipboard.clip.join( "\n" ) )
          end
        end
        retval.gsub!( /\$c/, clip_filename )
      end

      # Current klipper (KDE clipboard) text
      if retval =~ /\$k/
        clip_filename = @diakonos_home + "/clip.txt"
        File.open( clip_filename, "w" ) do |clipfile|
          clipfile.puts( `dcop klipper klipper getClipboardContents` )
        end
        retval.gsub!( /\$k/, clip_filename )
      end

      # Currently selected text
      if retval =~ /\$s/
        text_filename = @diakonos_home + "/selected.txt"

        File.open( text_filename, "w" ) do |textfile|
          selected_text = @current_buffer.selected_text
          if selected_text
            textfile.puts( selected_text.join( "\n" ) )
          end
        end
        retval.gsub!( /\$s/, text_filename )
      end

      retval
    end

    def startRecordingMacro( name = nil )
      return if @macro_history
      @macro_name = name
      @macro_history = Array.new
      @macro_input_history = Array.new
      setILine "Started macro recording."
    end
    protected :startRecordingMacro

    def stopRecordingMacro
      @macro_history.pop  # Remove the stopRecordingMacro command itself
      @macros[ @macro_name ] = [ @macro_history, @macro_input_history ]
      @macro_history = nil
      @macro_input_history = nil
      setILine "Stopped macro recording."
    end
    protected :stopRecordingMacro

    def loadTags
      @tags = Hash.new
      if @current_buffer and @current_buffer.name
        path = File.expand_path( File.dirname( @current_buffer.name ) )
        tagfile = path + "/tags"
      else
        tagfile = "./tags"
      end
      if FileTest.exists? tagfile
        IO.foreach( tagfile ) do |line_|
          line = line_.chomp
          # <tagname>\t<filepath>\t<line number or regexp>\t<kind of tag>
          tag, file, command, kind, rest = line.split( /\t/ )
          command.gsub!( /;"$/, "" )
          if command =~ /^\/.*\/$/
            command = command[ 1...-1 ]
          end
          @tags[ tag ] ||= Array.new
          @tags[ tag ].push CTag.new( file, command, kind, rest )
        end
      else
        setILine "(tags file not found)"
      end
    end

    def write_to_clip_file( text )
      clip_filename = @diakonos_home + "/clip.txt"
      File.open( clip_filename, "w" ) do |f|
        f.print text
      end
      clip_filename
    end

    # Returns true iff some text was copied to klipper.
    def send_to_klipper( text )
      return false if text.nil?

      clip_filename = write_to_clip_file( text.join( "\n" ) )
      # A little shell sorcery to ensure the shell doesn't strip off trailing newlines.
      # Thank you to pgas from irc.freenode.net#bash for help with this.
      `clipping=$(cat #{clip_filename};printf "_"); dcop klipper klipper setClipboardContents "${clipping%_}"`
      true
    end

    # Worker method for find function.
    def find_( direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, quiet )
      return if( regexp_source.nil? or regexp_source.empty? )

      rs_array = regexp_source.newlineSplit
      regexps = Array.new
      exception_thrown = nil

      rs_array.each do |source|
        begin
          warning_verbosity = $VERBOSE
          $VERBOSE = nil
          regexps << Regexp.new(
            source,
            case_sensitive ? nil : Regexp::IGNORECASE
          )
          $VERBOSE = warning_verbosity
        rescue RegexpError => e
          if not exception_thrown
            exception_thrown = e
            source = Regexp.escape( source )
            retry
          else
            raise e
          end
        end
      end

      if replacement == ASK_REPLACEMENT
        replacement = getUserInput( "Replace with: ", @rlh_search )
      end

      if exception_thrown and not quiet
        setILine( "Searching literally; #{exception_thrown.message}" )
      end

      @current_buffer.find(
        regexps,
        :direction    => direction,
        :replacement  => replacement,
        :starting_row => starting_row,
        :starting_col => starting_col,
        :quiet        => quiet
      )
      @last_search_regexps = regexps
    end

    def grep_( regexp_source, *buffers )
      original_buffer = @current_buffer
      if @current_buffer.changing_selection
        selected_text = @current_buffer.copySelection[ 0 ]
      end
      starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

      selected = getUserInput(
        "Grep regexp: ",
        @rlh_search,
        regexp_source || selected_text || ""
      ) { |input|
        next if input.length < 2
        begin
          regexp = Regexp.new( input, Regexp::IGNORECASE )
          grep_results = buffers.map { |buffer| buffer.grep( regexp ) }.flatten
          with_list_file do |list|
            list.puts grep_results.join( "\n---\n" )
          end
          list_buffer = openListBuffer
          list_buffer.highlightMatches regexp
          list_buffer.display
        rescue RegexpError
          # Do nothing
        end
      }

      if selected
        spl = selected.split( "| " )
        if spl.size > 1
          openFile spl[ -1 ]
        end
      else
        original_buffer.cursorTo starting_row, starting_col
      end
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  $diakonos = Diakonos::Diakonos.new( ARGV )
  $diakonos.start
end
