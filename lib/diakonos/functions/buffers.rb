module Diakonos
  module Functions

    # Closes a buffer.
    #
    # @param [Diakonos::Buffer] buffer
    #   The buffer to close.  If no buffer is provided, defaults to the current buffer.
    # @param [Fixnum] to_all
    #   the CHOICE to assume for the prompt.
    # @return [Fixnum] the choice the user made, or nil if the user was not prompted to choose.
    # @see Diakonos::CHOICE_YES
    # @see Diakonos::CHOICE_NO
    def close_file( buffer = @current_buffer, to_all = nil )
      return nil if buffer.nil?

      choice = nil
      if @buffers.has_value?( buffer )
        do_closure = true

        if buffer.modified?
          if not buffer.read_only
            if to_all.nil?
              choices = [ CHOICE_YES, CHOICE_NO, CHOICE_CANCEL ]
              if @quitting
                choices.concat [ CHOICE_YES_TO_ALL, CHOICE_NO_TO_ALL ]
              end
              choice = get_choice(
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
              save_file buffer
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
            ( @buffers.key( buf ) == del_buffer_key )
          ) do
            buf = @buffer_stack.pop
          end
          if @buffers.values.include?( buf )
            to_switch_to = buf
          end

          if to_switch_to
            switch_to( to_switch_to )
          elsif previous_buffer
            switch_to( previous_buffer )
          else
            # No buffers left.  Open a new blank one.
            open_file
          end

          @buffers.delete del_buffer_key
          save_session

          update_status_line
          update_context_line
        end
      else
        log "No such buffer: #{buffer.name}"
      end

      choice
    end

  end
end