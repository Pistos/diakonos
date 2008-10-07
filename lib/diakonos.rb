#!/usr/bin/env ruby

# == Diakonos
#
# A usable console text editor.
# :title: Diakonos
#
# Author:: Pistos (irc.freenode.net)
# http://purepistos.net/diakonos
# Copyright (c) 2004-2008 Pistos
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

require 'diakonos/object'
require 'diakonos/enumerable'
require 'diakonos/regexp'
require 'diakonos/sized-array'
require 'diakonos/hash'
require 'diakonos/buffer-hash'
require 'diakonos/array'
require 'diakonos/string'
require 'diakonos/keycode'
require 'diakonos/fixnum'
require 'diakonos/bignum'
require 'diakonos/text-mark'
require 'diakonos/bookmark'
require 'diakonos/ctag'
require 'diakonos/finding'
require 'diakonos/buffer'
require 'diakonos/window'
require 'diakonos/clipboard'
require 'diakonos/readline'

#$profiling = true

#if $profiling
    #require 'ruby-prof'
#end

module Diakonos

    VERSION = '0.8.6'
    LAST_MODIFIED = 'October 6, 2008'

    DONT_ADJUST_ROW = false
    ADJUST_ROW = true
    PROMPT_OVERWRITE = true
    DONT_PROMPT_OVERWRITE = false
    DO_REDRAW = true
    DONT_REDRAW = false
    QUIET = true
    NOISY = false

    TAB = 9
    ENTER = 13
    ESCAPE = 27
    BACKSPACE = 127
    CTRL_C = 3
    CTRL_D = 4
    CTRL_K = 11
    CTRL_Q = 17
    CTRL_H = 263
    RESIZE2 = 4294967295
    
    DEFAULT_TAB_SIZE = 8

    CHOICE_NO = 0
    CHOICE_YES = 1
    CHOICE_ALL = 2
    CHOICE_CANCEL = 3
    CHOICE_YES_TO_ALL = 4
    CHOICE_NO_TO_ALL = 5
    CHOICE_YES_AND_STOP = 6
    CHOICE_KEYS = [
        [ ?n, ?N ],
        [ ?y, ?Y ],
        [ ?a, ?A ],
        [ ?c, ?C, ESCAPE, CTRL_C, CTRL_D, CTRL_Q ],
        [ ?e ],
        [ ?o ],
        [ ?s ],
    ]
    CHOICE_STRINGS = [ '(n)o', '(y)es', '(a)ll', '(c)ancel', 'y(e)s to all', 'n(o) to all', 'yes and (s)top' ]

    BOL_ZERO = 0
    BOL_FIRST_CHAR = 1
    BOL_ALT_ZERO = 2
    BOL_ALT_FIRST_CHAR = 3

    EOL_END = 0
    EOL_LAST_CHAR = 1
    EOL_ALT_END = 2
    EOL_ALT_LAST_CHAR = 3

    FORCE_REVERT = true
    ASK_REVERT = false
    
    ASK_REPLACEMENT = true
    
    CASE_SENSITIVE = true
    CASE_INSENSITIVE = false

    FUNCTIONS = [
        'addNamedBookmark',
        'anchorSelection',
        'backspace',
        'carriageReturn',
        'changeSessionSetting',
        'clearMatches',
        'closeFile',
        'close_code',
        'collapseWhitespace',
        'copySelection',
        'copy_selection_to_klipper',
        'cursorBOF',
        'cursorBOL',
        'cursorBOV',
        'cursorDown',
        'cursorEOF',
        'cursorEOL',
        'cursorLeft',
        'cursorReturn',
        'cursorRight',
        'cursorTOV',
        'cursorUp',
        'cutSelection',
        'cut_selection_to_klipper',
        'delete',
        'deleteAndStoreLine',
        'deleteLine',
        'deleteToEOL',
        'delete_and_store_line_to_klipper',
        'delete_line_to_klipper',
        'delete_to_EOL_to_klipper',
        'evaluate',
        'execute',
        'find',
        'findAgain',
        'findAndReplace',
        'findExact',
        'goToLineAsk',
        'goToNamedBookmark',
        'goToNextBookmark',
        'goToPreviousBookmark',
        'goToTag',
        'goToTagUnderCursor',
        'help',
        'indent',
        'insertSpaces',
        'insertTab',
        'joinLines',
        'list_buffers',
        'loadConfiguration',
        'loadScript',
        'newFile',
        'openFile',
        'openFileAsk',
        'operateOnEachLine',
        'operateOnLines',
        'operateOnString',
        'pageDown',
        'pageUp',
        'parsedIndent',
        'paste',
        'pasteShellResult',
        'paste_from_klipper',
        'playMacro',
        'popTag',
        'printKeychain',
        'quit',
        'redraw',
        'removeNamedBookmark',
        'removeSelection',
        'repeatLast',
        'revert',
        'saveFile',
        'saveFileAs',
        'scrollDown',
        'scrollUp',
        'searchAndReplace',
        'seek',
        'select_block',
        'setBufferType',
        'setReadOnly',
        'shell',
        'showClips',
        'suspend',
        'switchToBufferNumber',
        'switchToNextBuffer',
        'switchToPreviousBuffer',
        'toggleBookmark',
        'toggleMacroRecording',
        'toggleSelection',
        'toggleSessionSetting',
        'undo',
        'unindent',
        'unundo'
    ]
    LANG_TEXT = 'text'
    
    NUM_LAST_COMMANDS = 2
    
class Diakonos
    attr_reader :win_main, :settings, :token_regexps, :close_token_regexps,
        :token_formats, :diakonos_home, :script_dir, :diakonos_conf, :display_mutex,
        :indenters, :unindenters, :closers, :clipboard, :do_display,
        :current_buffer, :list_filename, :hooks, :last_commands, :there_was_non_movement


    def initialize( argv = [] )
        @diakonos_home = ( ( ENV[ 'HOME' ] or '' ) + '/.diakonos' ).subHome
        if not FileTest.exists? @diakonos_home
            Dir.mkdir @diakonos_home
        end
        @script_dir = "#{@diakonos_home}/scripts"
        if not FileTest.exists? @script_dir
            Dir.mkdir @script_dir
        end
        @debug = File.new( "#{@diakonos_home}/debug.log", 'w' )
        @list_filename = @diakonos_home + '/listing.txt'
        @diff_filename = @diakonos_home + '/text.diff'
        @help_filename = @diakonos_home + '/help/about-help.txt'

        @files = Array.new
        @read_only_files = Array.new
        @config_filename = nil
        
        parseOptions argv
        
        @session_settings = Hash.new
        @win_main = nil
        @win_context = nil
        @win_status = nil
        @win_interaction = nil
        @buffers = BufferHash.new
        
        loadConfiguration
        
        @quitting = false
        @untitled_id = 0

        @x = 0
        @y = 0

        @buffer_stack = Array.new
        @current_buffer = nil
        @bookmarks = Hash.new
        @macro_history = nil
        @macro_input_history = nil
        @macros = Hash.new
        @last_commands = SizedArray.new( NUM_LAST_COMMANDS )
        @playing_macro = false
        @display_mutex = Mutex.new
        @display_queue_mutex = Mutex.new
        @display_queue = nil
        @do_display = true
        @iline_mutex = Mutex.new
        @tag_stack = Array.new
        @last_search_regexps = nil
        @iterated_choice = nil
        @choice_iterations = 0
        @there_was_non_movement = false
        
        # Readline histories
        @rlh_general = Array.new
        @rlh_files = Array.new
        @rlh_search = Array.new
        @rlh_shell = Array.new
        @rlh_help = Array.new
    end

    def parseOptions( argv )
        while argv.length > 0
            arg = argv.shift
            case arg
                when '-h', '--help'
                    printUsage
                    exit 1
                when '-ro'
                    filename = argv.shift
                    if filename == nil
                        printUsage
                        exit 1
                    else
                        @read_only_files.push filename
                    end
                when '-c', '--config'
                    @config_filename = argv.shift
                    if @config_filename == nil
                        printUsage
                        exit 1
                    end
                when '-e', '--execute'
                    post_load_script = argv.shift
                    if post_load_script == nil
                        printUsage
                        exit 1
                    else
                        @post_load_script = post_load_script
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
        puts "\t-ro <file>\tLoad file as read-only"
        puts "\t-c <config file>\tLoad this config file instead of ~/.diakonos/diakonos.conf"
        puts "\t-e, --execute <Ruby code>\tExecute Ruby code (such as Diakonos commands) after startup"
    end
    protected :printUsage
    
    def initializeDisplay
        if @win_main != nil
            @win_main.close
        end
        if @win_status != nil
            @win_status.close
        end
        if @win_interaction != nil
            @win_interaction.close
        end
        if @win_context != nil
            @win_context.close
        end

        Curses::init_screen
        Curses::nonl
        Curses::raw
        Curses::noecho

        if Curses::has_colors?
            Curses::start_color
            Curses::init_pair( Curses::COLOR_BLACK, Curses::COLOR_BLACK, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_RED, Curses::COLOR_RED, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_GREEN, Curses::COLOR_GREEN, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_YELLOW, Curses::COLOR_YELLOW, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_BLUE, Curses::COLOR_BLUE, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_MAGENTA, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_CYAN, Curses::COLOR_CYAN, Curses::COLOR_BLACK )
            Curses::init_pair( Curses::COLOR_WHITE, Curses::COLOR_WHITE, Curses::COLOR_BLACK )
            @colour_pairs.each do |cp|
                Curses::init_pair( cp[ :number ], cp[ :fg ], cp[ :bg ] )
            end
        end
        
        @win_main = Curses::Window.new( main_window_height, Curses::cols, 0, 0 )
        @win_main.keypad( true )
        @win_status = Curses::Window.new( 1, Curses::cols, Curses::lines - 2, 0 )
        @win_status.keypad( true )
        @win_status.attrset @settings[ 'status.format' ]
        @win_interaction = Curses::Window.new( 1, Curses::cols, Curses::lines - 1, 0 )
        @win_interaction.keypad( true )
        
        if @settings[ 'context.visible' ]
            if @settings[ 'context.combined' ]
                pos = 1
            else
                pos = 3
            end
            @win_context = Curses::Window.new( 1, Curses::cols, Curses::lines - pos, 0 )
            @win_context.keypad( true )
        else
            @win_context = nil
        end

        @win_interaction.refresh
        @win_main.refresh
        
        @buffers.each_value do |buffer|
            buffer.reset_win_main
        end
    end
    
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
      
      return found
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
            
            if not FileTest.exists?( @diakonos_conf )
                puts "Terminating..."
                exit 1
            end
        end

        @logfilename = @diakonos_home + "/diakonos.log"
        @keychains = Hash.new
        @token_regexps = Hash.new
        @close_token_regexps = Hash.new
        @token_formats = Hash.new
        @indenters = Hash.new
        @unindenters = Hash.new
        @filemasks = Hash.new
        @bangmasks = Hash.new
        @closers = Hash.new

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
            
            @session_settings.each do |key,value|
                @settings[ key ] = value
            end
            
            @clipboard = Clipboard.new @settings[ "max_clips" ]
            @log = File.open( @logfilename, "a" )

            if @buffers != nil
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
            next if command == nil
            command = command.downcase
            case command
                when "include"
                    parseConfigurationFile arg.subHome
                when "key"
                    if arg != nil
                        if /  / === arg
                            keystrings, function_and_args = arg.split( / {2,}/, 2 )
                        else
                            keystrings, function_and_args = arg.split( /;/, 2 )
                        end
                        keystrokes = Array.new
                        keystrings.split( /\s+/ ).each do |ks_str|
                            code = ks_str.keyCode
                            if code != nil
                                keystrokes.concat code
                            else
                                puts "unknown keystring: #{ks_str}"
                            end
                        end
                        if function_and_args == nil
                            @keychains.deleteKeyPath( keystrokes )
                        else
                            function, function_args = function_and_args.split( /\s+/, 2 )
                            if FUNCTIONS.include? function
                                @keychains.setKeyPath(
                                    keystrokes,
                                    [ function, function_args ]
                                )
                            end
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
                        "found_cursor_start", "convert_tabs", 'delete_newline_on_delete_to_eol'
                    @settings[ command ] = arg.to_b
                when "context.format", "context.separator.format", "status.format"
                    @settings[ command ] = arg.toFormatting
                when "logfile"
                    @logfilename = arg.subHome
                when "context.separator", "status.left", "status.right", "status.filler",
                        "status.modified_str", "status.unnamed_str", "status.selecting_str",
                        "status.read_only_str", /^lang\..+?\.indent\.ignore\.charset$/,
                        /^lang\.(.+?)\.tokens\.([^.]+)\.change_to$/, "view.nonfilelines.character",
                        'interaction.blink_string', 'diff_command'
                    @settings[ command ] = arg
                when "status.vars"
                    @settings[ command ] = arg.split( /\s+/ )
                when /^lang\.(.+?)\.indent\.size$/, /^lang\.(.+?)\.tabsize$/
                    @settings[ command ] = arg.to_i
                when "context.max_levels", "context.max_segment_width", "max_clips", "max_undo_lines",
                        "view.margin.x", "view.margin.y", "view.scroll_amount", "view.lookback"
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

    def getTokenRegexp( hash, arg, match )
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

    def redraw
        loadConfiguration
        initializeDisplay
        updateStatusLine
        updateContextLine
        @current_buffer.display
    end

    def log( string )
        @log.puts string
        @log.flush
    end
    
    def debugLog( string )
        @debug.puts( Time.now.strftime( "[%a %H:%M:%S] #{string}" ) )
        @debug.flush
    end
    
    def registerProc( proc, hook_name, priority = 0 )
        @hooks[ hook_name ] << { :proc => proc, :priority => priority }
    end
    
    def clearNonMovementFlag
        @there_was_non_movement = false
    end
    
    # -----------------------------------------------------------------------

    def main_window_height
        # One line for the status line
        # One line for the input line
        # One line for the context line
        retval = Curses::lines - 2
        if @settings[ "context.visible" ] and not @settings[ "context.combined" ]
            retval = retval - 1
        end
        return retval
    end

    def main_window_width
        return Curses::cols
    end

    def start
        initializeDisplay
        
        @hooks = {
            :after_save => [],
            :after_startup => [],
        }
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

        setILine "Diakonos #{VERSION} (#{LAST_MODIFIED})   F1 for help  F12 to configure   Ctrl-Q to quit"
        
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
        
        if num_opened > 0
            switchToBufferNumber 1
            
            updateStatusLine
            updateContextLine
            
            if @post_load_script != nil
                eval @post_load_script
            end
            
            runHookProcs( :after_startup )
            
            begin
                # Main keyboard loop.
                while not @quitting
                    processKeystroke
                    @win_main.refresh
                end
            rescue SignalException => e
                debugLog "Terminated by signal (#{e.message})"
            end
            
            @debug.close
        end
    end
    
    # context is an array of characters (bytes) which are keystrokes previously
    # typed (in a chain of keystrokes)
    def processKeystroke( context = [] )
        c = @win_main.getch
        
        if @capturing_keychain
            if c == ENTER
                @capturing_keychain = false
                @current_buffer.deleteSelection
                str = context.to_keychain_s.strip
                @current_buffer.insertString str 
                cursorRight( Buffer::STILL_TYPING, str.length )
            else
                keychain_pressed = context.concat [ c ]
                
                function_and_args = @keychains.getLeaf( keychain_pressed )
                
                if function_and_args != nil
                    function, args = function_and_args
                end
                
                partial_keychain = @keychains.getNode( keychain_pressed )
                if partial_keychain != nil
                    setILine( "Part of existing keychain: " + keychain_pressed.to_keychain_s + "..." )
                else
                    setILine keychain_pressed.to_keychain_s + "..."
                end
                processKeystroke( keychain_pressed )
            end
        else
        
            if context.empty?
                if c > 31 and c < 255 and c != BACKSPACE
                    if @macro_history != nil
                        @macro_history.push "typeCharacter #{c}"
                    end
                    if not @there_was_non_movement
                        @there_was_non_movement = true
                    end
                    typeCharacter c
                    return
                end
            end
            keychain_pressed = context.concat [ c ]
            
            function_and_args = @keychains.getLeaf( keychain_pressed )
            
            if function_and_args != nil
                function, args = function_and_args
                setILine if not @settings[ "context.combined" ]
                
                if args != nil
                    to_eval = "#{function}( #{args} )"
                else
                    to_eval = function
                end
                
                if @macro_history != nil
                    @macro_history.push to_eval
                end
                
                begin
                    eval to_eval, nil, "eval"
                    @last_commands << to_eval unless to_eval == "repeatLast"
                    if not @there_was_non_movement
                        @there_was_non_movement = ( not to_eval.movement? )
                    end
                rescue Exception => e
                    debugLog e.message
                    debugLog e.backtrace.join( "\n\t" )
                    showException e
                end
            else
                partial_keychain = @keychains.getNode( keychain_pressed )
                if partial_keychain != nil
                    setILine( keychain_pressed.to_keychain_s + "..." )
                    processKeystroke( keychain_pressed )
                else
                    setILine "Nothing assigned to #{keychain_pressed.to_keychain_s}"
                end
            end
        end
    end
    protected :processKeystroke

    # Display text on the interaction line.
    def setILine( string = "" )
        Curses::curs_set 0
        @win_interaction.setpos( 0, 0 )
        @win_interaction.addstr( "%-#{Curses::cols}s" % string )
        @win_interaction.refresh
        Curses::curs_set 1
        string.length
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

    def switchTo( buffer )
        switched = false
        if buffer
            @buffer_stack -= [ @current_buffer ]
            if @current_buffer
              @buffer_stack.push @current_buffer
            end
            @current_buffer = buffer
            updateStatusLine
            updateContextLine
            buffer.display
            switched = true
        end
        
        switched
    end
    protected :switchTo

    def buildStatusLine( truncation = 0 )
        var_array = Array.new
        @settings[ "status.vars" ].each do |var|
            case var
                when "buffer_number"
                    var_array.push bufferToNumber( @current_buffer )
                when "col"
                    var_array.push( @current_buffer.last_screen_col + 1 )
                when "filename"
                    name = @current_buffer.nice_name
                    var_array.push( name[ ([ truncation, name.length ].min)..-1 ] )
                when "modified"
                    if @current_buffer.modified
                        var_array.push @settings[ "status.modified_str" ]
                    else
                        var_array.push ""
                    end
                when "num_buffers"
                    var_array.push @buffers.length
                when "num_lines"
                    var_array.push @current_buffer.length
                when "row", "line"
                    var_array.push( @current_buffer.last_row + 1 )
                when "read_only"
                    if @current_buffer.read_only
                        var_array.push @settings[ "status.read_only_str" ]
                    else
                        var_array.push ""
                    end
                when "selecting"
                    if @current_buffer.changing_selection
                        var_array.push @settings[ "status.selecting_str" ]
                    else
                        var_array.push ""
                    end
                when "type"
                    var_array.push @current_buffer.original_language
            end
        end
        str = nil
        begin
            status_left = @settings[ "status.left" ]
            field_count = status_left.count "%"
            status_left = status_left % var_array[ 0...field_count ]
            status_right = @settings[ "status.right" ] % var_array[ field_count..-1 ]
            filler_string = @settings[ "status.filler" ]
            fill_amount = (Curses::cols - status_left.length - status_right.length) / filler_string.length
            if fill_amount > 0
                filler = filler_string * fill_amount
            else
                filler = ""
            end
            str = status_left + filler + status_right
        rescue ArgumentError => e
            str = "%-#{Curses::cols}s" % "(status line configuration error)"
        end
        return str
    end
    protected :buildStatusLine

    def updateStatusLine
        str = buildStatusLine
        if str.length > Curses::cols
            str = buildStatusLine( str.length - Curses::cols )
        end
        Curses::curs_set 0
        @win_status.setpos( 0, 0 )
        @win_status.addstr str
        @win_status.refresh
        Curses::curs_set 1
    end

    def updateContextLine
        if @win_context != nil
            @context_thread.exit if @context_thread != nil
            @context_thread = Thread.new do ||

                context = @current_buffer.context

                Curses::curs_set 0
                @win_context.setpos( 0, 0 )
                chars_printed = 0
                if context.length > 0
                    truncation = [ @settings[ "context.max_levels" ], context.length ].min
                    max_length = [
                        ( Curses::cols / truncation ) - @settings[ "context.separator" ].length,
                        ( @settings[ "context.max_segment_width" ] or Curses::cols )
                    ].min
                    line = nil
                    context_subset = context[ 0...truncation ]
                    context_subset = context_subset.collect do |line|
                        line.strip[ 0...max_length ]
                    end

                    context_subset.each do |line|
                        @win_context.attrset @settings[ "context.format" ]
                        @win_context.addstr line
                        chars_printed += line.length
                        @win_context.attrset @settings[ "context.separator.format" ]
                        @win_context.addstr @settings[ "context.separator" ]
                        chars_printed += @settings[ "context.separator" ].length
                    end
                end

                @iline_mutex.synchronize do
                    @win_context.attrset @settings[ "context.format" ]
                    @win_context.addstr( " " * ( Curses::cols - chars_printed ) )
                    @win_context.refresh
                end
                @display_mutex.synchronize do
                    @win_main.setpos( @current_buffer.last_screen_y, @current_buffer.last_screen_x )
                    @win_main.refresh
                end
                Curses::curs_set 1
            end
            
            @context_thread.priority = -2
        end
    end
    
    def displayEnqueue( buffer )
        @display_queue_mutex.synchronize do
            @display_queue = buffer
        end
    end
    
    def displayDequeue
        @display_queue_mutex.synchronize do
            if @display_queue != nil
                Thread.new( @display_queue ) do |b|
                    @display_mutex.lock
                    @display_mutex.unlock
                    b.display
                end
                @display_queue = nil
            end
        end
    end

    # completion_array is the array of strings that tab completion can use
    def getUserInput( prompt, history = @rlh_general, initial_text = "", completion_array = nil, &block )
        if @playing_macro
            retval = @macro_input_history.shift
        else
            retval = Readline.new( self, @win_interaction, prompt, initial_text, completion_array, history, &block ).readline
            if @macro_history != nil
                @macro_input_history.push retval
            end
            setILine
        end
        return retval
    end

    def getLanguageFromName( name )
        retval = nil
        @filemasks.each do |language,filemask|
            if name =~ filemask
                retval = language
                break
            end
        end
        return retval
    end
    
    def getLanguageFromShaBang( first_line )
        retval = nil
        @bangmasks.each do |language,bangmask|
            if first_line =~ /^#!/ and first_line =~ bangmask
                retval = language
                break
            end
        end
        return retval
    end
    
    def showException( e, probable_causes = [ "Unknown" ] )
        begin
            File.open( @diakonos_home + "/diakonos.err", "w" ) do |f|
                f.puts "Diakonos Error:"
                f.puts
                f.puts e.message
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
            openFile( @diakonos_home + "/diakonos.err" )
        rescue Exception => e2
            debugLog "EXCEPTION: #{e.message}"
            debugLog "\t#{e.backtrace}"
        end
    end
    
    def logBacktrace
        begin
            raise Exception
        rescue Exception => e
            e.backtrace[ 1..-1 ].each do |x|
                debugLog x
            end
        end
    end

    # The given buffer_number should be 1-based, not zero-based.
    # Returns nil if no such buffer exists.
    def bufferNumberToName( buffer_number )
        return nil if buffer_number < 1

        number = 1
        buffer_name = nil
        @buffers.each_key do |name|
            if number == buffer_number
                buffer_name = name
                break
            end
            number += 1
        end
        return buffer_name
    end

    # The returned value is 1-based, not zero-based.
    # Returns nil if no such buffer exists.
    def bufferToNumber( buffer )
        number = 1
        buffer_number = nil
        @buffers.each_value do |b|
            if b == buffer
                buffer_number = number
                break
            end
            number += 1
        end
        buffer_number
    end

    def subShellVariables( string )
        return nil if string == nil

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
                if @clipboard.clip != nil
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
                if selected_text != nil
                    textfile.puts( selected_text.join( "\n" ) )
                end
            end
            retval.gsub!( /\$s/, text_filename )
        end
        
        return retval
    end
    
    def showMessage( message, non_interaction_duration = @settings[ 'interaction.choice_delay' ] )
        terminateMessage
        
        @message_expiry = Time.now + non_interaction_duration
        @message_thread = Thread.new do
            time_left = @message_expiry - Time.now
            while time_left > 0
                setILine "(#{time_left.round}) #{message}"
                @win_main.setpos( @saved_main_y, @saved_main_x )
                sleep 1
                time_left = @message_expiry - Time.now
            end
            setILine message
            @win_main.setpos( @saved_main_y, @saved_main_x )
        end
    end
    
    def terminateMessage
        if @message_thread != nil and @message_thread.alive?
            @message_thread.terminate
            @message_thread = nil
        end
    end
    
    def interactionBlink( message = nil )
        terminateMessage
        setILine @settings[ 'interaction.blink_string' ]
        sleep @settings[ 'interaction.blink_duration' ]
        setILine message if message != nil
    end
    
    # choices should be an array of CHOICE_* constants.
    # default is what is returned when Enter is pressed.
    def getChoice( prompt, choices, default = nil )
        retval = @iterated_choice
        if retval != nil
            @choice_iterations -= 1
            if @choice_iterations < 1
                @iterated_choice = nil
                @do_display = true
            end
            return retval 
        end
        
        @saved_main_x = @win_main.curx
        @saved_main_y = @win_main.cury

        msg = prompt + " "
        choice_strings = choices.collect do |choice|
            CHOICE_STRINGS[ choice ]
        end
        msg << choice_strings.join( ", " )
        
        if default.nil?
            showMessage msg
        else
            setILine msg
        end
        
        c = nil
        while retval.nil?
            c = @win_interaction.getch
            
            case c
                when Curses::KEY_NPAGE
                    pageDown
                when Curses::KEY_PPAGE
                    pageUp
                else
                    if @message_expiry != nil and Time.now < @message_expiry
                        interactionBlink
                        showMessage msg
                    else
                        case c
                            when ENTER
                                retval = default
                            when ?0..?9
                                if @choice_iterations < 1
                                    @choice_iterations = ( c - ?0 )
                                else
                                    @choice_iterations = @choice_iterations * 10 + ( c - ?0 )
                                end
                            else
                                choices.each do |choice|
                                    if CHOICE_KEYS[ choice ].include? c
                                        retval = choice
                                        break
                                    end
                                end
                        end
                        
                        if retval.nil?
                            interactionBlink( msg )
                        end
                    end
            end
        end
        
        terminateMessage
        setILine

        if @choice_iterations > 0
            @choice_iterations -= 1
            @iterated_choice = retval
            @do_display = false
        end
        
        return retval
    end

    def startRecordingMacro( name = nil )
        return if @macro_history != nil
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

    def typeCharacter( c )
        @current_buffer.deleteSelection( Buffer::DONT_DISPLAY )
        @current_buffer.insertChar c
        cursorRight( Buffer::STILL_TYPING )
    end
    
    def loadTags
        @tags = Hash.new
        if @current_buffer != nil and @current_buffer.name != nil
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
    
    def refreshAll
        @win_main.refresh
        if @win_context != nil
            @win_context.refresh
        end
        @win_status.refresh
        @win_interaction.refresh
    end
    
    def openListBuffer
        @list_buffer = openFile( @list_filename )
    end
    
    def closeListBuffer
        closeFile( @list_buffer )
        @list_buffer = nil
    end
    def showing_list?
      @list_buffer
    end
    def list_item_selected?
      @list_buffer and @list_buffer.selecting?
    end
    def current_list_item
      if @list_buffer
        @list_buffer.select_current_line
      end
    end
    def select_list_item
      if @list_buffer
        line = @list_buffer.select_current_line
        @list_buffer.display
        line
      end
    end
    def previous_list_item
      if @list_buffer
        cursorUp
        @list_buffer[ @list_buffer.currentRow ]
      end
    end
    def next_list_item
      if @list_buffer
        cursorDown
        @list_buffer[ @list_buffer.currentRow ]
      end
    end
    
    def open_help_buffer
      @help_buffer = openFile( @help_filename )
    end
    def close_help_buffer
      closeFile @help_buffer
      @help_buffer = nil
    end
    
    def runHookProcs( hook_id, *args )
        @hooks[ hook_id ].each do |hook_proc|
            hook_proc[ :proc ].call( *args )
        end
    end
    
    # --------------------------------------------------------------------
    #
    # Program Functions

    def addNamedBookmark( name_ = nil )
        if name_ == nil
            name = getUserInput "Bookmark name: "
        else
            name = name_
        end

        if name != nil
            @bookmarks[ name ] = Bookmark.new( @current_buffer, @current_buffer.currentRow, @current_buffer.currentColumn, name )
            setILine "Added bookmark #{@bookmarks[ name ].to_s}."
        end
    end

    def anchorSelection
        @current_buffer.anchorSelection
        updateStatusLine
    end

    def backspace
        delete if( @current_buffer.changing_selection or cursorLeft( Buffer::STILL_TYPING ) )
    end

    def carriageReturn
        @current_buffer.carriageReturn
        @current_buffer.deleteSelection
    end
    
    def changeSessionSetting( key_ = nil, value = nil, do_redraw = DONT_REDRAW )
        if key_ == nil
            key = getUserInput( "Setting: " )
        else
            key = key_
        end

        if key != nil
            if value == nil
                value = getUserInput( "Value: " )
            end
            case @settings[ key ]
                when String
                    value = value.to_s
                when Fixnum
                    value = value.to_i
                when TrueClass, FalseClass
                    value = value.to_b
            end
            @session_settings[ key ] = value
            redraw if do_redraw
            setILine "#{key} = #{value}"
        end
    end

    def clearMatches
        @current_buffer.clearMatches Buffer::DO_DISPLAY
    end
    
    def close_code
        @current_buffer.close_code
    end

    # Returns the choice the user made, or nil if the user was not prompted to choose.
    def closeFile( buffer = @current_buffer, to_all = nil )
        return nil if buffer == nil
        
        choice = nil
        if @buffers.has_value?( buffer )
            do_closure = true

            if buffer.modified
                if not buffer.read_only
                    if to_all == nil
                        choices = [ CHOICE_YES, CHOICE_NO, CHOICE_CANCEL ]
                        if @quitting
                            choices.concat [ CHOICE_YES_TO_ALL, CHOICE_NO_TO_ALL ]
                        end
                        choice = getChoice(
                            "Save changes to #{buffer.nice_name}?",
                            choices,
                            CHOICE_CANCEL
                        )
                    else
                        choice = to_all
                    end
                    case choice
                        when CHOICE_YES, CHOICE_YES_TO_ALL
                            do_closure = true
                            saveFile( buffer )
                        when CHOICE_NO, CHOICE_NO_TO_ALL
                            do_closure = true
                        when CHOICE_CANCEL
                            do_closure = false
                    end
                end
            end

            if do_closure
                del_buffer_key = nil
                previous_buffer = nil
                to_switch_to = nil
                switching = false
                
                # Search the buffer hash for the buffer we want to delete,
                # and mark the one we will switch to after deletion.
                @buffers.each do |buffer_key,buf|
                    if switching
                        to_switch_to = buf
                        break
                    end
                    if buf == buffer
                        del_buffer_key = buffer_key
                        switching = true
                        next
                    end
                    previous_buffer = buf
                end
                
                buf = nil
                while(
                    ( not @buffer_stack.empty? ) and
                    ( not @buffers.values.include?( buf ) ) or
                    ( @buffers.index( buf ) == del_buffer_key )
                ) do
                    buf = @buffer_stack.pop
                end
                if @buffers.values.include?( buf )
                    to_switch_to = buf
                end
                
                if to_switch_to != nil
                    switchTo( to_switch_to )
                elsif previous_buffer != nil
                    switchTo( previous_buffer )
                else
                    # No buffers left.  Open a new blank one.
                    openFile
                end

                @buffers.delete del_buffer_key

                updateStatusLine
                updateContextLine
            end
        else
            log "No such buffer: #{buffer.name}"
        end

        return choice
    end
    
    def collapseWhitespace
        @current_buffer.collapseWhitespace
    end

    def copySelection
        @clipboard.addClip @current_buffer.copySelection
        removeSelection
    end

    def copy_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        removeSelection
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

    # Returns true iff the cursor changed positions
    def cursorDown
        return @current_buffer.cursorTo( @current_buffer.last_row + 1, @current_buffer.last_col, Buffer::DO_DISPLAY, Buffer::STOPPED_TYPING, DONT_ADJUST_ROW )
    end

    # Returns true iff the cursor changed positions
    def cursorLeft( stopped_typing = Buffer::STOPPED_TYPING )
        return @current_buffer.cursorTo( @current_buffer.last_row, @current_buffer.last_col - 1, Buffer::DO_DISPLAY, stopped_typing )
    end

    def cursorRight( stopped_typing = Buffer::STOPPED_TYPING, amount = 1 )
        return @current_buffer.cursorTo( @current_buffer.last_row, @current_buffer.last_col + amount, Buffer::DO_DISPLAY, stopped_typing )
    end

    # Returns true iff the cursor changed positions
    def cursorUp
        return @current_buffer.cursorTo( @current_buffer.last_row - 1, @current_buffer.last_col, Buffer::DO_DISPLAY, Buffer::STOPPED_TYPING, DONT_ADJUST_ROW )
    end

    def cursorBOF
        @current_buffer.cursorTo( 0, 0, Buffer::DO_DISPLAY )
    end

    def cursorBOL
        @current_buffer.cursorToBOL
    end

    def cursorEOL
      @current_buffer.cursorToEOL
    end

    def cursorEOF
        @current_buffer.cursorToEOF
    end

    # Top of view
    def cursorTOV
        @current_buffer.cursorToTOV
    end

    # Bottom of view
    def cursorBOV
        @current_buffer.cursorToBOV
    end
    
    def cursorReturn( dir_str = "backward" )
        stack_pointer, stack_size = @current_buffer.cursorReturn( dir_str.toDirection( :backward ) )
        setILine( "Location: #{stack_pointer+1}/#{stack_size}" )
    end

    def cutSelection
        delete if @clipboard.addClip( @current_buffer.copySelection )
    end
    
    def cut_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        delete
      end
    end

    def delete
        @current_buffer.delete
    end

    def delete_and_store_line_to_klipper
      removed_text = @current_buffer.deleteLine
      if removed_text
        if @last_commands[ -1 ] =~ /^delete_and_store_line_to_klipper/
          clip_filename = write_to_clip_file( removed_text << "\n" )
          `clipping="$(dcop klipper klipper getClipboardContents)\n$(cat #{clip_filename};printf "_")"; dcop klipper klipper setClipboardContents "${clipping%_}"`
        else
          send_to_klipper [ removed_text, "" ]
        end
      end
    end

    def deleteAndStoreLine
      removed_text = @current_buffer.deleteLine
      if removed_text
        clip = [ removed_text, "" ]
        if @last_commands[ -1 ] =~ /^deleteAndStoreLine/
          @clipboard.appendToClip clip
        else
          @clipboard.addClip clip
        end
      end
    end

    def delete_line_to_klipper
        removed_text = @current_buffer.deleteLine
        if removed_text
          send_to_klipper [ removed_text, "" ]
        end
    end
    
    def deleteLine
        removed_text = @current_buffer.deleteLine
        @clipboard.addClip( [ removed_text, "" ] ) if removed_text
    end

    def delete_to_EOL_to_klipper
        removed_text = @current_buffer.deleteToEOL
        if removed_text
          send_to_klipper removed_text
        end
    end
    
    def deleteToEOL
        removed_text = @current_buffer.deleteToEOL
        @clipboard.addClip( removed_text ) if removed_text
    end
    
    def evaluate( code_ = nil )
        if code_ == nil
            if @current_buffer.changing_selection
                selected_text = @current_buffer.copySelection[ 0 ]
            end
            code = getUserInput( "Ruby code: ", @rlh_general, ( selected_text or "" ), FUNCTIONS )
        else
            code = code_
        end
        
        if code != nil
            begin
                eval code
            rescue Exception => e
                showException(
                    e,
                    [
                        "The code given to evaluate has a syntax error.",
                        "The code given to evaluate refers to a Diakonos command which does not exist, or is misspelled.",
                        "The code given to evaluate refers to a Diakonos command with missing arguments.",
                        "The code given to evaluate refers to a variable or method which does not exist.",
                    ]
                )
            end
        end
    end
    
    def find( dir_str = "down", case_sensitive = CASE_INSENSITIVE, regexp_source_ = nil, replacement = nil )
      direction = dir_str.toDirection
      if regexp_source_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copySelection[ 0 ]
        end
        starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col
        
        regexp_source = getUserInput(
          "Search regexp: ",
          @rlh_search,
          ( selected_text or "" )
        ) { |input|
          if input.length > 1
            find_ direction, case_sensitive, input, replacement, starting_row, starting_col, QUIET
          else
            @current_buffer.removeSelection Buffer::DONT_DISPLAY
            @current_buffer.clearMatches Buffer::DO_DISPLAY
          end
        }
      else
        regexp_source = regexp_source_
      end
      
      find_ direction, case_sensitive, regexp_source, replacement, starting_row, starting_col, NOISY
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
        :direction => direction,
        :replacement => replacement,
        :starting_row => starting_row,
        :starting_col => starting_col,
        :quiet => quiet
      )
      @last_search_regexps = regexps
    end

    def findAgain( dir_str = nil )
        if dir_str != nil
            direction = dir_str.toDirection
            @current_buffer.findAgain( @last_search_regexps, direction )
        else
            @current_buffer.findAgain( @last_search_regexps )
        end
    end

    def findAndReplace
        searchAndReplace
    end

    def findExact( dir_str = "down", search_term_ = nil )
        if search_term_ == nil
            if @current_buffer.changing_selection
                selected_text = @current_buffer.copySelection[ 0 ]
            end
            search_term = getUserInput( "Search for: ", @rlh_search, ( selected_text or "" ) )
        else
            search_term = search_term_
        end
        if search_term != nil
            direction = dir_str.toDirection
            regexp = Regexp.new( Regexp.escape( search_term ) )
            @current_buffer.find( regexp, :direction => direction )
            @last_search_regexps = regexp
        end
    end

    def goToLineAsk
        input = getUserInput( "Go to [line number|+lines][,column number]: " )
        if input != nil
            row = nil
            
            if input =~ /([+-]\d+)/
                row = @current_buffer.last_row + $1.to_i
                col = @current_buffer.last_col
            else
                input = input.split( /\D+/ ).collect { |n| n.to_i }
                if input.size > 0
                    if input[ 0 ] == 0
                        row = nil
                    else
                        row = input[ 0 ] - 1
                    end
                    if input[ 1 ] != nil
                        col = input[ 1 ] - 1
                    end
                end
            end
            
            if row
                @current_buffer.goToLine( row, col )
            end
        end
    end

    def goToNamedBookmark( name_ = nil )
        if name_ == nil
            name = getUserInput "Bookmark name: "
        else
            name = name_
        end

        if name != nil
            bookmark = @bookmarks[ name ]
            if bookmark != nil
                switchTo( bookmark.buffer )
                bookmark.buffer.cursorTo( bookmark.row, bookmark.col, Buffer::DO_DISPLAY )
            else
                setILine "No bookmark named '#{name}'."
            end
        end
    end

    def goToNextBookmark
        @current_buffer.goToNextBookmark
    end

    def goToPreviousBookmark
        @current_buffer.goToPreviousBookmark
    end

    def goToTag( tag_ = nil )
        loadTags
        
        # If necessary, prompt for tag name.
        
        if tag_ == nil
            if @current_buffer.changing_selection
                selected_text = @current_buffer.copySelection[ 0 ]
            end
            tag_name = getUserInput( "Tag name: ", @rlh_general, ( selected_text or "" ), @tags.keys )
        else
            tag_name = tag_
        end

        tag_array = @tags[ tag_name ]
        if tag_array != nil and tag_array.length > 0
            if i = tag_array.index( @last_tag )
                tag = ( tag_array[ i + 1 ] or tag_array[ 0 ] )
            else
                tag = tag_array[ 0 ]
            end
            @last_tag = tag
            @tag_stack.push [ @current_buffer.name, @current_buffer.last_row, @current_buffer.last_col ]
            if switchTo( @buffers[ tag.file ] )
                #@current_buffer.goToLine( 0 )
            else
                openFile( tag.file )
            end
            line_number = tag.command.to_i
            if line_number > 0
                @current_buffer.goToLine( line_number - 1 )
            else
                find( "down", CASE_SENSITIVE, tag.command )
            end
        elsif tag_name != nil
            setILine "No such tag: '#{tag_name}'"
        end
    end
    
    def goToTagUnderCursor
        goToTag @current_buffer.wordUnderCursor
    end
    
    def with_list_file
      File.open( @list_filename, "w" ) do |f|
        yield f
      end
    end
    
    def help
      open_help_buffer
      
      selected = getUserInput(
        "Search terms: ",
        @rlh_help
      ) { |input|
        next if input.length < 3
        with_list_file do |list|
          files = `egrep -l '^Tags.*\\b#{input}\\b' #{@diakonos_home}/help/*`
          files.split( /\s+/ ).each do |file|
            File.open( file ) do |f|
              # Write title to list
              list.puts( "%-40s | %s" % [ f.gets.strip, file ] )
            end
          end
        end
        
        openListBuffer
      }
      
      close_help_buffer
      
      if selected and not selected.empty?
        help_file = selected.split( "| " )[ -1 ]
        if File.exist? help_file
          openFile help_file
        end
      end
    end

    def indent
        if( @current_buffer.changing_selection )
            @do_display = false
            mark = @current_buffer.selection_mark
            if mark.end_col > 0
                end_row = mark.end_row
            else
                end_row = mark.end_row - 1
            end
            (mark.start_row..end_row).each do |row|
                @current_buffer.indent row, Buffer::DONT_DISPLAY
            end
            @do_display = true
            @current_buffer.display
        else
            @current_buffer.indent
        end
    end
    
    def insertSpaces( num_spaces )
        if num_spaces > 0
            @current_buffer.deleteSelection
            @current_buffer.insertString( " " * num_spaces )
            cursorRight( Buffer::STILL_TYPING, num_spaces )
        end
    end
    
    def insertTab
        typeCharacter( TAB )
    end
    
    def joinLines
        @current_buffer.joinLines( @current_buffer.currentRow, Buffer::STRIP_LINE )
    end

    def list_buffers
      with_list_file do |f|
        f.puts @buffers.keys.map { |name| "#{name}\n" }.sort
      end
      openListBuffer
      filename = getUserInput( "Switch to buffer: " )
      buffer = @buffers[ filename ]
      if buffer
        switchTo buffer
      end
    end
    
    def loadScript( name_ = nil )
        if name_ == nil
            name = getUserInput( "File to load as script: ", @rlh_files )
        else
            name = name_
        end

        if name != nil
            thread = Thread.new( name ) do |f|
                begin
                    load( f )
                rescue Exception => e
                    showException(
                        e,
                        [
                            "The filename given does not exist.",
                            "The filename given is not accessible or readable.",
                            "The loaded script does not reference Diakonos commands as members of the global Diakonos object.  e.g. cursorBOL instead of $diakonos.cursorBOL",
                            "The loaded script has syntax errors.",
                            "The loaded script references objects or object members which do not exist."
                        ]
                    )
                end
                setILine "Loaded script '#{name}'."
            end

            loop do
                if thread.status != "run"
                    break
                else
                    sleep 0.1
                end
            end
            thread.join
        end
    end

    def newFile
        openFile
    end

    # Returns the buffer of the opened file, or nil.
    def openFile( filename = nil, read_only = false, force_revert = ASK_REVERT )
      do_open = true
      buffer = nil
      if filename.nil?
        buffer_key = @untitled_id
        @untitled_id += 1
      else
        if filename =~ /^(.+):(\d+)$/
          filename, line_number = $1, ( $2.to_i - 1 )
        end
        buffer_key = filename
        if(
          (not force_revert) and
          ( (existing_buffer = @buffers[ filename ]) != nil ) and
          ( filename !~ /\.diakonos/ )
        )
          switchTo( existing_buffer )
          choice = getChoice(
            "Revert to on-disk version of #{existing_buffer.nice_name}?",
            [ CHOICE_YES, CHOICE_NO ]
          )
          case choice
          when CHOICE_NO
            do_open = false
          end
        end
      
        if FileTest.exist?( filename )
          # Don't try to open non-files (i.e. directories, pipes, sockets, etc.)
          do_open &&= FileTest.file?( filename )
        end
      end
      
      if do_open
        # Is file readable?
        
        # Does the "file" utility exist?
        if(
          filename and
          @settings[ 'use_magic_file' ] and
          FileTest.exist?( "/usr/bin/file" ) and
          FileTest.exist?( filename ) and
          /\blisting\.txt\b/ !~ filename
        )
          file_type = `/usr/bin/file -L #{filename}`
          if file_type !~ /text/ and file_type !~ /empty$/
            choice = getChoice(
              "#{filename} does not appear to be readable.  Try to open it anyway?",
              [ CHOICE_YES, CHOICE_NO ],
              CHOICE_NO
            )
            case choice
            when CHOICE_NO
              do_open = false
            end
            
          end
        end
        
        if do_open
          buffer = Buffer.new( self, filename, buffer_key, read_only )
          @buffers[ buffer_key ] = buffer
          if switchTo( buffer ) and line_number
            @current_buffer.goToLine( line_number, 0 )
          end
        end
      end
      
      buffer
    end
  
    def openFileAsk
        if @current_buffer != nil and @current_buffer.name != nil
            path = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
            file = getUserInput( "Filename: ", @rlh_files, path )
        else
            file = getUserInput( "Filename: ", @rlh_files )
        end
        if file != nil
            openFile file
            updateStatusLine
            updateContextLine
        end
    end
    
    def operateOnString(
        ruby_code = getUserInput( 'Ruby code: ', @rlh_general, 'str.' )
    )
        if ruby_code != nil
            str = @current_buffer.selected_string
            if str != nil and not str.empty?
                @current_buffer.paste eval( ruby_code )
            end
        end
    end

    def operateOnLines(
        ruby_code = getUserInput( 'Ruby code: ', @rlh_general, 'lines.collect { |l| l }' )
    )
        if ruby_code != nil
            lines = @current_buffer.selected_text
            if lines != nil and not lines.empty?
                if lines[ -1 ].empty?
                    lines.pop
                    popped = true
                end
                new_lines = eval( ruby_code )
                if popped
                    new_lines << ''
                end
                @current_buffer.paste new_lines
            end
        end
    end

    def operateOnEachLine(
        ruby_code = getUserInput( 'Ruby code: ', @rlh_general, 'line.' )
    )
        if ruby_code != nil
            lines = @current_buffer.selected_text
            if lines != nil and not lines.empty?
                if lines[ -1 ].empty?
                    lines.pop
                    popped = true
                end
                new_lines = eval( "lines.collect { |line| #{ruby_code} }" )
                if popped
                    new_lines << ''
                end
                @current_buffer.paste new_lines
            end
        end
    end

    def pageUp
        if @current_buffer.pitchView( -main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
            cursorBOF
        end
        updateStatusLine
        updateContextLine
    end

    def pageDown
        if @current_buffer.pitchView( main_window_height, Buffer::DO_PITCH_CURSOR ) == 0
            @current_buffer.cursorToEOF
        end
        updateStatusLine
        updateContextLine
    end

    def parsedIndent
        if( @current_buffer.changing_selection )
            @do_display = false
            mark = @current_buffer.selection_mark
            (mark.start_row..mark.end_row).each do |row|
                @current_buffer.parsedIndent row, Buffer::DONT_DISPLAY
            end
            @do_display = true
            @current_buffer.display
        else
            @current_buffer.parsedIndent
        end
        updateStatusLine
        updateContextLine
    end

    def paste
        @current_buffer.paste @clipboard.clip
    end
    
    def paste_from_klipper
      text = `dcop klipper klipper getClipboardContents`.split( "\n", -1 )
      text.pop  # getClipboardContents puts an extra newline on end
      @current_buffer.paste text
    end

    def playMacro( name = nil )
        macro, input_history = @macros[ name ]
        if input_history != nil
            @macro_input_history = input_history.deep_clone
            if macro != nil
                @playing_macro = true
                macro.each do |command|
                    eval command
                end
                @playing_macro = false
                @macro_input_history = nil
            end
        end
    end
    
    def popTag
        tag = @tag_stack.pop
        if tag != nil
            if not switchTo( @buffers[ tag[ 0 ] ] )
                openFile( tag[ 0 ] )
            end
            @current_buffer.cursorTo( tag[ 1 ], tag[ 2 ], Buffer::DO_DISPLAY )
        else
            setILine "Tag stack empty."
        end
    end
    
    def printKeychain
        @capturing_keychain = true
        setILine "Type any chain of keystrokes or key chords, then press Enter..."
    end

    def quit
        @quitting = true
        to_all = nil
        @buffers.each_value do |buffer|
            if buffer.modified
                switchTo buffer
                closure_choice = closeFile( buffer, to_all )
                case closure_choice
                    when CHOICE_CANCEL
                        @quitting = false
                        break
                    when CHOICE_YES_TO_ALL, CHOICE_NO_TO_ALL
                        to_all = closure_choice
                end
            end
        end
    end

    def removeNamedBookmark( name_ = nil )
        if name_ == nil
            name = getUserInput "Bookmark name: "
        else
            name = name_
        end

        if name != nil
            bookmark = @bookmarks.delete name
            setILine "Removed bookmark #{bookmark.to_s}."
        end
    end

    def removeSelection
        @current_buffer.removeSelection
        updateStatusLine
    end

    def repeatLast
        eval @last_commands[ -1 ] if not @last_commands.empty?
    end

    # If the prompt is non-nil, ask the user yes or no question first.
    def revert( prompt = nil )
        do_revert = true
        
        current_text_file = @diakonos_home + '/current-buffer'
        @current_buffer.saveCopy( current_text_file )
        `#{@settings[ 'diff_command' ]} #{current_text_file} #{@current_buffer.name} > #{@diff_filename}`
        diff_buffer = openFile( @diff_filename )
        
        if prompt != nil
            choice = getChoice(
                prompt,
                [ CHOICE_YES, CHOICE_NO ]
            )
            case choice
                when CHOICE_NO
                    do_revert = false
            end
        end
        
        closeFile( diff_buffer )
        
        if do_revert
            openFile( @current_buffer.name, Buffer::READ_WRITE, FORCE_REVERT )
        end
    end

    def saveFile( buffer = @current_buffer )
        buffer.save
        runHookProcs( :after_save, buffer )
    end

    def saveFileAs
        if @current_buffer != nil and @current_buffer.name != nil
            path = File.expand_path( File.dirname( @current_buffer.name ) ) + "/"
            file = getUserInput( "Filename: ", @rlh_files, path )
        else
            file = getUserInput( "Filename: ", @rlh_files )
        end
        if file != nil
            #old_name = @current_buffer.name
            @current_buffer.save( file, PROMPT_OVERWRITE )
            #if not @current_buffer.modified
                # Save was okay.
                #@buffers.delete old_name
                #@buffers[ @current_buffer.name ] = @current_buffer
                #switchTo( @current_buffer )
            #end
        end
    end
    
    def select_block( beginning = nil, ending = nil, including_ending = true )
      if beginning.nil?
        beginning = Regexp.new( getUserInput( "Start at regexp: " ) )
      end
      if ending.nil?
        ending = Regexp.new( getUserInput( "End before regexp: " ) )
      end
      @current_buffer.select( beginning, ending, including_ending )
    end

    def scrollDown
        @current_buffer.pitchView( @settings[ "view.scroll_amount" ] || 1 )
        updateStatusLine
        updateContextLine
    end

    def scrollUp
        if @settings[ "view.scroll_amount" ] != nil
            @current_buffer.pitchView( -@settings[ "view.scroll_amount" ] )
        else
            @current_buffer.pitchView( -1 )
        end
        updateStatusLine
        updateContextLine
    end

    def searchAndReplace( case_sensitive = CASE_INSENSITIVE )
        find( "down", case_sensitive, nil, ASK_REPLACEMENT )
    end
    
    def seek( regexp_source, dir_str = "down" )
        if regexp_source != nil
            direction = dir_str.toDirection
            regexp = Regexp.new( regexp_source )
            @current_buffer.seek( regexp, direction )
        end
    end

    def setBufferType( type_ = nil )
        if type_ == nil
            type = getUserInput "Content type: "
        else
            type = type_
        end

        if type != nil
            if @current_buffer.setType( type )
                updateStatusLine
                updateContextLine
            end
        end
    end

    # If read_only is nil, the read_only state of the current buffer is toggled.
    # Otherwise, the read_only state of the current buffer is set to read_only.
    def setReadOnly( read_only = nil )
        if read_only != nil
            @current_buffer.read_only = read_only
        else
            @current_buffer.read_only = ( not @current_buffer.read_only )
        end
        updateStatusLine
    end

    def shell( command_ = nil )
        if command_ == nil
            command = getUserInput( "Command: ", @rlh_shell )
        else
            command = command_
        end

        if command != nil
            command = subShellVariables( command )

            result_file = @diakonos_home + "/shell-result.txt"
            File.open( result_file , "w" ) do |f|
                f.puts command
                f.puts
                Curses::close_screen

                stdin, stdout, stderr = Open3.popen3( command )
                t1 = Thread.new do
                    stdout.each_line do |line|
                        f.puts line
                    end
                end
                t2 = Thread.new do
                    stderr.each_line do |line|
                        f.puts line
                    end
                end

                t1.join
                t2.join

                Curses::init_screen
                refreshAll
            end
            openFile result_file
        end
    end
    
    def execute( command_ = nil )
        if command_ == nil
            command = getUserInput( "Command: ", @rlh_shell )
        else
            command = command_
        end

        if command != nil
            command = subShellVariables( command )

            Curses::close_screen

            success = system( command )
            if not success
                result = "Could not execute: #{command}"
            else
                result = "Return code: #{$?}"
            end

            Curses::init_screen
            refreshAll
            
            setILine result
        end
    end
    
    def pasteShellResult( command_ = nil )
        if command_ == nil
            command = getUserInput( "Command: ", @rlh_shell )
        else
            command = command_
        end

        if command != nil
            command = subShellVariables( command )

            Curses::close_screen
            
            begin
                @current_buffer.paste( `#{command} 2<&1`.split( /\n/, -1 ) )
            rescue Exception => e
                debugLog e.message
                debugLog e.backtrace.join( "\n\t" )
                showException e
            end
            
            Curses::init_screen
            refreshAll
        end
    end
    
    # Send the Diakonos job to background, as if with Ctrl-Z
    def suspend
        Curses::close_screen
        Process.kill( "SIGSTOP", $PID )
        Curses::init_screen
        refreshAll
    end

    def toggleMacroRecording( name = nil )
        if @macro_history != nil
            stopRecordingMacro
        else
            startRecordingMacro( name )
        end
    end

    def switchToBufferNumber( buffer_number_ )
        buffer_number = buffer_number_.to_i
        return if buffer_number < 1
        buffer_name = bufferNumberToName( buffer_number )
        if buffer_name
            switchTo( @buffers[ buffer_name ] )
        end
    end

    def switchToNextBuffer
        buffer_number = bufferToNumber( @current_buffer )
        switchToBufferNumber( buffer_number + 1 )
    end

    def switchToPreviousBuffer
        buffer_number = bufferToNumber( @current_buffer )
        switchToBufferNumber( buffer_number - 1 )
    end

    def toggleBookmark
        @current_buffer.toggleBookmark
    end
    
    def toggleSelection
        @current_buffer.toggleSelection
        updateStatusLine
    end

    def toggleSessionSetting( key_ = nil, do_redraw = DONT_REDRAW )
        if key_ == nil
            key = getUserInput( "Setting: " )
        else
            key = key_
        end

        if key != nil
            value = nil
            if @session_settings[ key ].class == TrueClass or @session_settings[ key ].class == FalseClass
                value = ! @session_settings[ key ]
            elsif @settings[ key ].class == TrueClass or @settings[ key ].class == FalseClass
                value = ! @settings[ key ]
            end
            if value != nil
                @session_settings[ key ] = value
                redraw if do_redraw
                setILine "#{key} = #{value}"
            end
        end
    end
    
    def undo( buffer = @current_buffer )
        buffer.undo
    end

    def unindent
        if( @current_buffer.changing_selection )
            @do_display = false
            mark = @current_buffer.selection_mark
            if mark.end_col > 0
                end_row = mark.end_row
            else
                end_row = mark.end_row - 1
            end
            (mark.start_row..end_row).each do |row|
                @current_buffer.unindent row, Buffer::DONT_DISPLAY
            end
            @do_display = true
            @current_buffer.display
        else
            @current_buffer.unindent
        end
    end

    def unundo( buffer = @current_buffer )
        buffer.unundo
    end
end

end

if __FILE__ == $PROGRAM_NAME
    $diakonos = Diakonos::Diakonos.new( ARGV )
    $diakonos.start
end
