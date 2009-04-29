module Diakonos
  module Functions

    def delete_to( char = nil )
      if char.nil?
        set_iline "Type character to delete to..."
        char = @win_main.getch
        set_iline
      end
      if char
        removed_text = @current_buffer.delete_to char
        if removed_text
          @clipboard.add_clip removed_text
        else
          set_iline "'#{char}' not found."
        end
      end
    end

    def delete_to_and_from( char = nil )
      if char.nil?
        set_iline "Type character to delete to and from..."
        char = @win_main.getch
        set_iline
      end
      if char
        removed_text = @current_buffer.delete_to_and_from char
        if removed_text
          @clipboard.add_clip( [ removed_text ] )
        else
          set_iline "'#{char}' not found."
        end
      end
    end

    def evaluate( code_ = nil )
      if code_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        code = get_user_input( "Ruby code: ", @rlh_general, ( selected_text or "" ), ::Diakonos::Functions.public_instance_methods )
      else
        code = code_
      end

      if code
        begin
          eval code
        rescue Exception => e
          show_exception(
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

    def go_to_tag( tag_ = nil )
      load_tags

      # If necessary, prompt for tag name.

      if tag_.nil?
        if @current_buffer.changing_selection
          selected_text = @current_buffer.copy_selection[ 0 ]
        end
        tag_name = get_user_input( "Tag name: ", @rlh_general, ( selected_text or "" ), @tags.keys )
      else
        tag_name = tag_
      end

      tag_array = @tags[ tag_name ]
      if tag_array and tag_array.length > 0
        if i = tag_array.index( @last_tag )
          tag = ( tag_array[ i + 1 ] or tag_array[ 0 ] )
        else
          tag = tag_array[ 0 ]
        end
        @last_tag = tag
        @tag_stack.push [ @current_buffer.name, @current_buffer.last_row, @current_buffer.last_col ]
        if switch_to( @buffers[ tag.file ] )
          #@current_buffer.go_to_line( 0 )
        else
          open_file tag.file
        end
        line_number = tag.command.to_i
        if line_number > 0
          @current_buffer.go_to_line( line_number - 1 )
        else
          find( "down", CASE_SENSITIVE, tag.command )
        end
      elsif tag_name
        set_iline "No such tag: '#{tag_name}'"
      end
    end

    def go_to_tag_under_cursor
      go_to_tag @current_buffer.word_under_cursor
    end

    def help( prefill = '' )
      if ! File.exist?( @help_dir ) || Dir[ "#{@help_dir}/*" ].size == 0
        set_iline 'There are no help files installed.'
        return
      end

      open_help_buffer
      matching_docs = nil

      selected = get_user_input(
        "Search terms: ",
        @rlh_help,
        prefill,
        @help_tags
      ) { |input|
        next if input.length < 3 and input[ 0..0 ] != '/'

        matching_docs = matching_help_documents( input )
        with_list_file do |list|
          list.puts matching_docs.join( "\n" )
        end

        open_list_buffer
      }

      close_help_buffer

      case selected
      when /\|/
        open_help_document selected
      when nil
        # Help search aborted; do nothing
      else
        # Not a selected help document
        if matching_docs.nil? or matching_docs.empty?
          matching_docs = matching_help_documents( selected )
        end

        case matching_docs.size
        when 1
          open_help_document matching_docs[ 0 ]
        when 0
          File.open( @error_filename, 'w' ) do |f|
            f.puts "There were no help documents matching your search."
            f.puts "(#{selected.strip})"
          end
          error_file = open_file( @error_filename )

          choice = get_choice(
            "Send your search terms to purepistos.net to help improve Diakonos?",
            [ CHOICE_YES, CHOICE_NO ]
          )
          case choice
          when CHOICE_YES
            require 'net/http'
            require 'uri'

            res = Net::HTTP.post_form(
              URI.parse( 'http://dh.purepistos.net/' ),
              { 'q' => selected }
            )
            # TODO: let them choose "never" and "always"
          end

          close_file error_file
        else
          help selected
        end
      end
    end

    def load_script( name_ = nil )
      if name_.nil?
        name = get_user_input( "File to load as script: ", @rlh_files )
      else
        name = name_
      end

      if name
        thread = Thread.new( name ) do |f|
          begin
            load( f )
          rescue Exception => e
            show_exception(
              e,
              [
                "The filename given does not exist.",
                "The filename given is not accessible or readable.",
                "The loaded script does not reference Diakonos commands as members of the global Diakonos object.  e.g. cursor_bol instead of $diakonos.cursor_bol",
                "The loaded script has syntax errors.",
                "The loaded script references objects or object members which do not exist."
              ]
            )
          end
          set_iline "Loaded script '#{name}'."
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

    def play_macro( name = nil )
      macro, input_history = @macros[ name ]
      if input_history
        @macro_input_history = input_history.deep_clone
        if macro
          @playing_macro = true
          macro.each do |command|
            eval command
          end
          @playing_macro = false
          @macro_input_history = nil
        end
      end
    end

    def pop_tag
      tag = @tag_stack.pop
      if tag
        if not switch_to( @buffers[ tag[ 0 ] ] )
          open_file tag[ 0 ]
        end
        @current_buffer.cursor_to( tag[ 1 ], tag[ 2 ], Buffer::DO_DISPLAY )
      else
        set_iline "Tag stack empty."
      end
    end

    def print_mapped_function
      @capturing_mapping = true
      set_iline "Type any chain of keystrokes or key chords, or press Enter to stop."
    end

    def print_keychain
      @capturing_keychain = true
      set_iline "Type any chain of keystrokes or key chords, then press Enter..."
    end

    def quit
      @quitting = true
      to_all = nil
      @buffers.each_value do |buffer|
        if buffer.modified?
          switch_to buffer
          closure_choice = close_file( buffer, to_all )
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

    def repeat_last
      eval @last_commands[ -1 ] if not @last_commands.empty?
    end

    # Send the Diakonos job to background, as if with Ctrl-Z
    def suspend
      Curses::close_screen
      Process.kill( "SIGSTOP", $PID )
      Curses::init_screen
      refresh_all
    end

    def toggle_macro_recording( name = nil )
      if @macro_history
        stop_recording_macro
      else
        start_recording_macro name
      end
    end

    def undo( buffer = @current_buffer )
      buffer.undo
    end

    def unundo( buffer = @current_buffer )
      buffer.unundo
    end

  end
end