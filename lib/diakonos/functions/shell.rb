module Diakonos
  module Functions

    # Change the current working directory (CWD) of the Diakonos process.
    # @param [String] dir  The directory to change to
    def chdir( dir = nil )
      dir ||= get_user_input( "Change to directory: ", initial_text: Dir.pwd )
      if dir
        Dir.chdir dir
      end
    end

    # Substitutes Diakonos shell variables in a String.
    # - $f: The current buffer's filename
    # - $d: The current buffer's directory
    # - $F: A space-separated list of all buffer filenames
    # - $i: A string acquired from the user with a prompt
    # - $c: The current clipboard text
    # - $s: The currently selected text
    # @param [String] string
    #   The string containing variables to substitute
    # @return [String]
    #   A new String with values substituted for all variables
    def sub_shell_variables( string )
      return  if string.nil?

      retval = string.dup

      # Current buffer filename
      retval.gsub!( /\$f/, ( $1 or "" ) + File.expand_path( @current_buffer.name || "" ) )
      # Current buffer dir
      retval.gsub!( /\$d/, ( $1 or "" ) + File.dirname( File.expand_path( @current_buffer.name || '' ) ) )

      # space-separated list of all buffer filenames
      name_array = Array.new
      @buffers.each_value do |b|
        name_array.push b.name
      end
      retval.gsub!( /\$F/, ( $1 or "" ) + ( name_array.join(' ') or "" ) )

      # Get user input, sub it in
      if retval =~ /\$i/
        user_input = get_user_input(
          "Argument: ",
          history: @rlh_shell,
          initial_text: @current_buffer.selected_string
        )
        retval.gsub!( /\$i/, user_input )
      end

      # Current clipboard text
      if retval =~ /\$[ck]/
        clip_filename = @diakonos_home + "/clip.txt"
        File.open( clip_filename, "w" ) do |clipfile|
          if @clipboard.clip
            clipfile.puts( @clipboard.clip.join( "\n" ) )
          end
        end
        retval.gsub!( /\$[ck]/, clip_filename )
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

    # Executes a command in a shell, captures the results, and displays them
    # (if any) in a new buffer.  Substitutes Diakonos shell variables.
    # Interaction with Diakonos is not possible while the shell is running.
    # For asynchronous shelling, use #spawn.  The shell function does not
    # allow interaction with applications run in the shell.  Use #execute
    # for interactivity.
    #
    # @param [String] command_
    #   The shell command to execute
    # @param [String] result_filename
    #   The name of the temporary file to write the shell results to
    # @see #sub_shell_variables
    # @see #execute
    # @see #spawn
    # @see #paste_shell_result
    def shell( command_ = nil, result_filename = 'shell-result.txt' )
      command = command_ || get_user_input( "Command: ", history: @rlh_shell )

      return  if command.nil?

      command = sub_shell_variables( command )

      completed = false
      result_file = "#{@diakonos_home}/#{result_filename}"
      File.open( result_file , "w" ) do |f|
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

        catch :stop do
          loop do
            begin
              Timeout::timeout( 5 ) do
                t1.join
                t2.join
                Curses::init_screen
                refresh_all
                completed = true
                throw :stop
              end
            rescue Timeout::Error => e
              choice = get_choice(
                "Keep waiting for shell results?",
                [ CHOICE_YES, CHOICE_NO ],
                CHOICE_YES
              )
              if choice != CHOICE_YES
                t1.terminate
                t2.terminate
                throw :stop
              end
            end
          end
        end

      end
      if File.size?( result_file )
        open_file result_file
        set_iline "#{completed ? '' : '(interrupted) '}Results for: #{command}"
      else
        set_iline "Empty result for: #{command}"
      end
    end

    # Executes a command in a shell, and displays the exit code.
    # Results of the shell command are discarded.
    # Substitutes Diakonos shell variables.
    # Interaction with Diakonos is not possible while the shell is running.
    # For asynchronous shelling, use #spawn.  The #execute function allows
    # interaction with shell programs that accept keyboard interaction.
    #
    # @param [String] command_
    #   The shell command to execute
    # @see #sub_shell_variables
    # @see #shell
    # @see #spawn
    # @see #paste_shell_result
    def execute( command_ = nil )
      command = command_ || get_user_input( "Command: ", history: @rlh_shell )

      return  if command.nil?

      command = sub_shell_variables( command )

      Curses::close_screen

      success = system( command )
      if ! success
        result = "Could not execute: #{command}"
      else
        result = "Exit code: #{$?}"
      end

      Curses::init_screen
      refresh_all

      set_iline result
    end

    # Executes a command in a shell, captures the results, and pastes them
    # in the current buffer at the current cursor location.
    # Substitutes Diakonos shell variables.
    # Interaction with Diakonos is not possible while the shell is running.
    # For asynchronous shelling, use #spawn.
    #
    # @param [String] command_
    #   The shell command to execute
    # @see #sub_shell_variables
    # @see #execute
    # @see #shell
    # @see #spawn
    def paste_shell_result( command_ = nil )
      command = command_ || get_user_input( "Command: ", history: @rlh_shell )

      return  if command.nil?

      command = sub_shell_variables( command )

      Curses::close_screen

      begin
        @current_buffer.paste( `#{command} 2<&1`.split( /\n/, -1 ) )
      rescue Exception => e
        debug_log e.message
        debug_log e.backtrace.join( "\n\t" )
        show_exception e
      end

      Curses::init_screen
      refresh_all
    end

    # Executes a command in a shell, captures the results, and pastes them
    # in the current buffer at the current cursor location.
    # Substitutes Diakonos shell variables.
    # The shell is executed in a separate thread, so interaction with Diakonos
    # is possible during execution.
    #
    # @param [String] command_
    #   The shell command to execute
    # @see #sub_shell_variables
    # @see #execute
    # @see #shell
    # @see #paste_shell_result
    def spawn( command_ = nil )
      command = command_ || get_user_input( "Command: ", history: @rlh_shell )

      return  if command.nil?

      command = sub_shell_variables( command )

      Thread.new do
        if system( command )
          set_iline "Return code #{$?} from '#{command}'"
        else
          set_iline "Error code #{$?} executing '#{command}'"
        end
      end
    end

  end
end