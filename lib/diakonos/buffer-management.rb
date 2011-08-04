module Diakonos
  class Diakonos
    attr_reader :buffer_current

    # @param [Buffer] the Buffer to switch to
    # @return [Boolean] true iff the buffer was successfully switched to
    def switch_to( buffer )
      return false  if buffer.nil?

      @buffer_stack -= [ @buffer_current ]
      if @buffer_current
        @buffer_stack.push @buffer_current
      end
      @buffer_current = buffer
      @session[ 'buffer_current' ] = buffer_to_number( buffer )
      run_hook_procs( :after_buffer_switch, buffer )
      update_status_line
      update_context_line
      display_buffer buffer

      true
    end

    # @param [Fixnum] buffer_number should be 1-based, not zero-based.
    # @return nil if no such buffer exists.
    def buffer_number_to_name( buffer_number )
      return nil  if buffer_number < 1

      b = @buffers[ buffer_number - 1 ]
      if b
        b.name
      end
    end

    # @return [Fixnum] 1-based, not zero-based.
    # @return nil if no such buffer exists.
    def buffer_to_number( buffer )
      i = @buffers.index( buffer )
      if i
        i + 1
      end
    end

    def show_buffer_file_diff( buffer = @buffer_current )
      current_text_file = @diakonos_home + '/current-buffer'
      buffer.save_copy( current_text_file )
      `#{@settings[ 'diff_command' ]} #{current_text_file} #{buffer.name} > #{@diff_filename}`
      diff_buffer = open_file( @diff_filename )
      yield diff_buffer
      close_buffer diff_buffer
    end

  end
end