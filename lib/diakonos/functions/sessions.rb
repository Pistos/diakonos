module Diakonos
  module Functions

    def merge_session_settings
      @settings.merge! @session.settings
    end

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
        when Integer
          value = value.to_i
        when TrueClass, FalseClass
          value = value.to_b
        end
        @session.settings[ key ] = value
        merge_session_settings
        redraw  if do_redraw
        set_iline "#{key} = #{value}"
      end
    end

    def name_session
      name = get_user_input( 'Session name: ' )
      if name
        @session = Session.new("#{@session_dir}/#{name}")
        save_session
      end
    end

    def set_session_dir
      path = get_user_input(
        "Session directory: ",
        history: @rlh_files,
        initial_text: @session.dir,
        do_complete: DONT_COMPLETE,
        on_dirs: :accept_dirs
      )
      if path
        @session.dir = File.expand_path( path )
        save_session
        set_iline "Session dir changed to: #{@session.dir}"
      else
        set_iline "(Session dir is: #{@session.dir})"
      end
    end

    def toggle_session_setting( key_ = nil, do_redraw = DONT_REDRAW )
      key = key_ || get_user_input( "Setting: " )
      return  if key.nil?

      value = nil
      if @session.settings[ key ].class == TrueClass || @session.settings[ key ].class == FalseClass
        value = ! @session.settings[ key ]
      elsif @settings[ key ].class == TrueClass || @settings[ key ].class == FalseClass
        value = ! @settings[ key ]
      end
      if value != nil   # explicitly true or false
        @session.settings[ key ] = value
        merge_session_settings
        redraw  if do_redraw
        set_iline "#{key} = #{value}"
      end
    end

  end
end
