module Diakonos
  DO_REDRAW             = true
  DONT_REDRAW           = false

  class Diakonos
    attr_reader :win_main, :display_mutex, :win_line_numbers

    def cleanup_display
      return  if @testing

      @win_main.close          if @win_main
      @win_status.close        if @win_status
      @win_interaction.close   if @win_interaction
      @win_context.close       if @win_context
      @win_line_numbers.close  if @win_line_numbers

      Curses::close_screen
    end

    def initialize_display
      if ! @testing
        cleanup_display

        Curses::init_screen
        Curses::nonl
        Curses::raw
        Curses::noecho
        if @settings['mouse']
          Curses::mousemask(Curses::ALL_MOUSE_EVENTS)
        end

        if Curses::has_colors?
          Curses::start_color
          Curses::use_default_colors

          # -1 means use the terminal's current/default background, which may even have some transparency
          background_colour = settings['colour.background'] || -1
          Curses::init_pair( Curses::COLOR_BLACK, Curses::COLOR_BLACK, background_colour )
          Curses::init_pair( Curses::COLOR_RED, Curses::COLOR_RED, background_colour )
          Curses::init_pair( Curses::COLOR_GREEN, Curses::COLOR_GREEN, background_colour )
          Curses::init_pair( Curses::COLOR_YELLOW, Curses::COLOR_YELLOW, background_colour )
          Curses::init_pair( Curses::COLOR_BLUE, Curses::COLOR_BLUE, background_colour )
          Curses::init_pair( Curses::COLOR_MAGENTA, Curses::COLOR_MAGENTA, background_colour )
          Curses::init_pair( Curses::COLOR_CYAN, Curses::COLOR_CYAN, background_colour )
          Curses::init_pair( Curses::COLOR_WHITE, Curses::COLOR_WHITE, background_colour )
          @colour_pairs.each do |cp|
            Curses::init_pair( cp[ :number ], cp[ :fg ], cp[ :bg ] )
          end
        end
      end

      if settings[ 'view.line_numbers' ]
        @win_line_numbers = ::Diakonos::Window.new( main_window_height, settings[ 'view.line_numbers.width' ], 0, 0 )
        @win_main = ::Diakonos::Window.new( main_window_height, Curses::cols - settings[ 'view.line_numbers.width' ], 0, settings[ 'view.line_numbers.width' ] )
      else
        @win_main = ::Diakonos::Window.new( main_window_height, Curses::cols, 0, 0 )
        @win_line_numbers = nil
      end
      @win_status = ::Diakonos::Window.new( 1, Curses::cols, Curses::lines - 2, 0 )
      @win_status.attrset @settings[ 'status.format' ]
      @win_interaction = ::Diakonos::Window.new( 1, Curses::cols, Curses::lines - 1, 0 )

      if @settings['context.visible']
        if @settings['context.combined']
          pos = 1
        else
          pos = 3
        end
        @win_context = ::Diakonos::Window.new( 1, Curses::cols, Curses::lines - pos, 0 )
      else
        @win_context = nil
      end

      if ! @testing
        @win_main.keypad( true )
        @win_status.keypad( true )
        @win_interaction.keypad( true )
        if @win_line_numbers
          @win_line_numbers.keypad( true )
        end
        if @win_context
          @win_context.keypad( true )
        end
      end

      @modes[ 'edit' ].window = @win_main
      @modes[ 'input' ].window = @win_interaction

      @win_interaction.refresh
      @win_main.refresh
      if @win_line_numbers
        @win_line_numbers.refresh
      end

      if @buffers
        @buffers.each do |buffer|
          buffer.reset_display
        end
      end
    end

    def redraw
      load_configuration
      initialize_display
      update_status_line
      update_context_line
      display_buffer buffer_current
    end

    def main_window_height
      # One line for the status line
      # One line for the input line
      # One line for the context line
      retval = Curses::lines - 2
      if @settings['context.visible'] && ! @settings['context.combined']
        retval = retval - 1
      end
      retval
    end

    def main_window_width
      Curses::cols
    end

    # Display text on the interaction line.
    def set_iline( string = "" )
      return  if @testing
      return  if @readline

      @iline = string
      Curses::curs_set 0
      @win_interaction.setpos( 0, 0 )
      @win_interaction.addstr( "%-#{Curses::cols}s" % @iline )
      @win_interaction.refresh
      Curses::curs_set 1
      string.length
    end

    def set_iline_if_empty( string )
      if @iline.nil? || @iline.empty?
        set_iline string
      end
    end

    def set_status_variable( identifier, value )
      @status_vars[ identifier ] = value
    end

    def build_status_line( truncation = 0 )
      var_array = Array.new
      @settings[ "status.vars" ].each do |var|
        case var
        when "buffer_number"
          var_array.push buffer_to_number( buffer_current )
        when "col"
          var_array.push( buffer_current.last_screen_col + 1 )
        when "filename"
          name = buffer_current.nice_name
          var_array.push name[ ([ truncation, name.length ].min)..-1 ]
        when "modified"
          if buffer_current.modified?
            var_array.push @settings[ "status.modified_str" ]
          else
            var_array.push ""
          end
        when "num_buffers"
          var_array.push @buffers.length
        when "num_lines"
          var_array.push buffer_current.length
        when "row", "line"
          var_array.push( buffer_current.last_row + 1 )
        when "read_only"
          if buffer_current.read_only
            var_array.push @settings[ "status.read_only_str" ]
          else
            var_array.push ""
          end
        when "selecting"
          if buffer_current.changing_selection
            var_array.push @settings[ "status.selecting_str" ]
          else
            var_array.push ""
          end
        when 'selection_mode'
          case buffer_current.selection_mode
          when :block
            var_array.push 'block'
          else
            var_array.push ''
          end
        when 'session_name'
          var_array.push @session.name
        when "type"
          var_array.push buffer_current.original_language
        when /^@/
          var_array.push @status_vars[ var ]
        end
      end
      str = nil
      begin
        status_left = @settings[ "status.left" ]
        field_count = status_left.count "%"
        status_left = status_left % var_array[ 0...field_count ]
        status_right = @settings[ "status.right" ] % var_array[ field_count..-1 ]
        filler_string = @settings[ "status.filler" ]
        fill_amount = (Curses::cols - status_left.length - status_right.length) / filler_string.length
        if fill_amount > 0
          filler = filler_string * fill_amount
        else
          filler = ""
        end
        str = status_left + filler + status_right
      rescue ArgumentError, TypeError => e
        debug_log e
        debug_log e.backtrace[ 0 ]
        debug_log "var_array: #{var_array.inspect}"
        str = "%-#{Curses::cols}s" % "(status line configuration error)"
      end
      str
    end
    protected :build_status_line

    def update_status_line
      return  if @testing

      str = build_status_line
      if str.length > Curses::cols
        str = build_status_line( str.length - Curses::cols )
      end
      Curses::curs_set 0
      @win_status.setpos( 0, 0 )
      @win_status.addstr str
      @win_status.refresh
      Curses::curs_set 1
    end

    def update_context_line
      return  if @testing
      return  if @win_context.nil?

      @context_thread.exit  if @context_thread
      @context_thread = Thread.new do
        context = buffer_current.context

        Curses::curs_set 0
        @win_context.setpos( 0, 0 )
        chars_printed = 0
        if context.length > 0
          truncation = [ @settings[ "context.max_levels" ], context.length ].min
          max_length = [
            ( Curses::cols / truncation ) - @settings[ "context.separator" ].length,
            ( @settings[ "context.max_segment_width" ] || Curses::cols )
          ].min
          line = nil
          context_subset = context[ 0...truncation ]
          context_subset = context_subset.collect do |line|
            line.strip[ 0...max_length ]
          end

          context_subset.each do |line|
            @win_context.attrset @settings[ "context.format" ]
            @win_context.addstr line
            chars_printed += line.length
            @win_context.attrset @settings[ "context.separator.format" ]
            @win_context.addstr @settings[ "context.separator" ]
            chars_printed += @settings[ "context.separator" ].length
          end
        end

        @iline_mutex.synchronize do
          @win_context.attrset @settings[ "context.format" ]
          @win_context.addstr( " " * ( Curses::cols - chars_printed ) )
          @win_context.refresh
        end
        @display_mutex.synchronize do
          @win_main.setpos( buffer_current.last_screen_y, buffer_current.last_screen_x )
          @win_main.refresh
        end
        Curses::curs_set 1
      end

      @context_thread.priority = -2
    end

    def display_buffer( buffer )
      return  if @testing
      return  if ! @do_display

      Thread.new do

        if ! @display_mutex.try_lock
          @display_queue_mutex.synchronize do
            @display_queue = buffer
          end
        else
          begin
            Curses::curs_set 0
            buffer.display
            Curses::curs_set 1
          rescue Exception => e
            $diakonos.log( "Display Exception:" )
            $diakonos.log( e.message )
            $diakonos.log( e.backtrace.join( "\n" ) )
            show_exception e
          end

          @display_mutex.unlock

          @display_queue_mutex.synchronize do
            if @display_queue
              b = @display_queue
              @display_queue = nil
              display_buffer b
            end
          end
        end

      end

    end

    def show_message( message, non_interaction_duration = @settings[ 'interaction.choice_delay' ] )
      terminate_message

      @message_expiry = Time.now + non_interaction_duration
      @message_thread = Thread.new do
        time_left = @message_expiry - Time.now
        while time_left > 0
          set_iline "(#{time_left.round}) #{message}"
          @win_main.setpos( @saved_main_y, @saved_main_x )
          sleep 1
          time_left = @message_expiry - Time.now
        end
        set_iline message
        @win_main.setpos( @saved_main_y, @saved_main_x )
      end
    end

    def terminate_message
      if @message_thread && @message_thread.alive?
        @message_thread.terminate
        @message_thread = nil
      end
    end

    def refresh_all
      @win_main.refresh
      if @win_context
        @win_context.refresh
      end
      @win_status.refresh
      @win_interaction.refresh
      if @win_line_numbers
        @win_line_numbers.refresh
      end
    end

  end

end
