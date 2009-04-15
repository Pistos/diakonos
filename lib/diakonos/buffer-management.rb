module Diakonos
  class Diakonos
    attr_reader :current_buffer

    def switch_to( buffer )
      switched = false
      if buffer
        @buffer_stack -= [ @current_buffer ]
        if @current_buffer
          @buffer_stack.push @current_buffer
        end
        @current_buffer = buffer
        run_hook_procs( :after_buffer_switch, buffer )
        update_status_line
        update_context_line
        buffer.display
        switched = true
      end

      switched
    end
    protected :switch_to

    def remember_buffer( buffer )
      if @buffer_history.last != buffer
        @buffer_history << buffer
        @buffer_history_pointer = @buffer_history.size - 1
      end
    end

    # The given buffer_number should be 1-based, not zero-based.
    # Returns nil if no such buffer exists.
    def buffer_number_to_name( buffer_number )
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
      buffer_name
    end

    # The returned value is 1-based, not zero-based.
    # Returns nil if no such buffer exists.
    def buffer_to_number( buffer )
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

    def show_buffer_file_diff( buffer = @current_buffer )
      current_text_file = @diakonos_home + '/current-buffer'
      buffer.save_copy( current_text_file )
      `#{@settings[ 'diff_command' ]} #{current_text_file} #{buffer.name} > #{@diff_filename}`
      diff_buffer = openFile( @diff_filename )
      yield diff_buffer
      close_file diff_buffer
    end

  end
end