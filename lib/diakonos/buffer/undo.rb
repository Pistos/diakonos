module Diakonos

  class Buffer

    DO_USE_MD5 = true
    DONT_USE_MD5 = false

    def take_snapshot( typing = false )
      do_it = false

      if ! @modified && file_modified? && file_different?
        return  if $diakonos.revert( "File has been altered externally.  Load on-disk version?" )
      end

      if @typing != typing
        @typing = typing
        # If we just started typing, take a snapshot, but don't continue
        # taking snapshots for every keystroke
        if typing
          do_it = true
        end
      end
      if not @typing
        do_it = true
      end

      if do_it
        undo_size = 0
        @buffer_states[ 1..-1 ].each do |state|
          undo_size += state.length
        end
        while ( ( undo_size + @lines.length ) >= @settings[ "max_undo_lines" ] ) and @buffer_states.length > 1
          @cursor_states.pop
          popped_state = @buffer_states.pop
          undo_size = undo_size - popped_state.length
        end
        if @current_buffer_state > 0
          @buffer_states.unshift @lines.deep_clone
          @cursor_states.unshift [ @last_row, @last_col ]
        end
        @buffer_states.unshift @lines.deep_clone
        @cursor_states.unshift [ @last_row, @last_col ]
        @current_buffer_state = 0
        @lines = @buffer_states[ @current_buffer_state ]
      end
    end

    def undo
      if @current_buffer_state < @buffer_states.length - 1
        @current_buffer_state += 1
        @lines = @buffer_states[ @current_buffer_state ]
        cursor_to( @cursor_states[ @current_buffer_state - 1 ][ 0 ], @cursor_states[ @current_buffer_state - 1 ][ 1 ] )
        $diakonos.set_iline "Undo level: #{@current_buffer_state} of #{@buffer_states.length - 1}"
        set_modified DO_DISPLAY, DO_USE_MD5
      end
    end

    # Since redo is a Ruby keyword...
    def unundo
      if @current_buffer_state > 0
        @current_buffer_state += -1
        @lines = @buffer_states[ @current_buffer_state ]
        cursor_to( @cursor_states[ @current_buffer_state ][ 0 ], @cursor_states[ @current_buffer_state ][ 1 ] )
        $diakonos.set_iline "Undo level: #{@current_buffer_state} of #{@buffer_states.length - 1}"
        set_modified DO_DISPLAY, DO_USE_MD5
      end
    end

  end

end