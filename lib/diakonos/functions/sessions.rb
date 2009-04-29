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

  end
end