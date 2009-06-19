module Diakonos
  module Functions

    def grep( regexp_source = nil )
      grep_( regexp_source, @current_buffer )
    end

    def grep_buffers( regexp_source = nil )
      grep_( regexp_source, *@buffers.values )
    end

    def grep_session_dir( regexp_source = nil )
      grep_dir regexp_source, @session[ 'dir' ]
    end

    def grep_dir( regexp_source = nil, dir = nil )
      if dir.nil?
        dir = get_user_input(
          "Grep directory: ",
          history: @rlh_files,
          initial_text: @session[ 'dir' ],
          do_complete: DONT_COMPLETE,
          on_dirs: :accept_dirs
        )
        return if dir.nil?
      end
      dir = File.expand_path( dir )

      original_buffer = @current_buffer
      if @current_buffer.changing_selection
        selected_text = @current_buffer.copy_selection[ 0 ]
      end
      starting_row, starting_col = @current_buffer.last_row, @current_buffer.last_col

      selected = get_user_input(
        "Grep regexp: ",
        history: @rlh_search,
        initial_text: regexp_source || selected_text || ""
      ) { |input|
        next if input.length < 2
        escaped_input = input.gsub( /'/ ) { "\\047" }
        matching_files = `egrep '#{escaped_input}' -rniIl #{dir}`.split( /\n/ )

        grep_results = matching_files.map { |f|
          ::Diakonos.grep_array(
            Regexp.new( input ),
            File.read( f ).split( /\n/ ),
            settings[ 'grep.context' ],
            "#{File.basename( f )}:",
            f
          )
        }.flatten
        if settings[ 'grep.context' ] == 0
          join_str = "\n"
        else
          join_str = "\n---\n"
        end
        with_list_file do |list|
          list.puts grep_results.join( join_str )
        end

        list_buffer = open_list_buffer
        regexp = nil
        begin
          list_buffer.highlight_matches Regexp.new( input )
        rescue RegexpError => e
          # ignore
        end
        list_buffer.display
      }

      if selected
        spl = selected.split( "| " )
        if spl.size > 1
          open_file spl[ -1 ]
        end
      else
        original_buffer.cursor_to starting_row, starting_col
      end
    end

  end
end