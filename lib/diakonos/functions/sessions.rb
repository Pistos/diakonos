module Diakonos
  module Functions

    def change_session_setting( key_ = nil, value = nil, do_redraw = DONT_REDRAW )
      if key_.nil?
        key = get_user_input( "Setting: " )
      else
        key = key_
      end

      if key
        if value.nil?
          value = get_user_input( "Value: " )
        end
        case @settings[ key ]
        when String
          value = value.to_s
        when Fixnum
          value = value.to_i
        when TrueClass, FalseClass
          value = value.to_b
        end
        @session[ 'settings' ][ key ] = value
        redraw  if do_redraw
        set_iline "#{key} = #{value}"
      end
    end

    def load_session( session_id = nil )
      if session_id.nil?
        session_id = get_user_input(
          "Session: ",
          history: @rlh_sessions,
          initial_text: @session_dir,
          do_complete: DO_COMPLETE
        )
      end
      return if session_id.nil? or session_id.empty?

      path = session_filepath_for( session_id )
      if not File.exist?( path )
        set_iline "No such session: #{session_id}"
      else
        if pid_session?( @session[ 'filename' ] )
          File.delete @session[ 'filename' ]
        end
        @session = nil
        @buffers.each_value do |buffer|
          close_file buffer
        end
        new_session( path )
        @session[ 'files' ].each do |file|
          open_file file
        end
      end
    end

    def name_session
      name = get_user_input( 'Session name: ' )
      if name
        new_session "#{@session_dir}/#{name}"
        save_session
      end
    end

    def set_session_dir
      path = get_user_input(
        "Session directory: ",
        history: @rlh_files,
        initial_text: @session[ 'dir' ],
        do_complete: DONT_COMPLETE,
        on_dirs: :accept_dirs
      )
      if path
        @session[ 'dir' ] = File.expand_path( path )
        save_session
        set_iline "Session dir changed to: #{@session['dir']}"
      else
        set_iline "(Session dir is: #{@session['dir']})"
      end
    end

    def toggle_session_setting( key_ = nil, do_redraw = DONT_REDRAW )
      key = key_ || get_user_input( "Setting: " )
      return  if key.nil?

      value = nil
      if @session[ 'settings' ][ key ].class == TrueClass or @session[ 'settings' ][ key ].class == FalseClass
        value = ! @session[ 'settings' ][ key ]
      elsif @settings[ key ].class == TrueClass or @settings[ key ].class == FalseClass
        value = ! @settings[ key ]
      end
      if value != nil   # explicitly true or false
        @session[ 'settings' ][ key ] = value
        redraw  if do_redraw
        set_iline "#{key} = #{value}"
      end
    end

  end
end