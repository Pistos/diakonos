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

    def initializeDisplay
      if ! @testing
        cleanup_display

        Curses::init_screen
        Curses::nonl
        Curses::raw
        Curses::noecho

        if Curses::has_colors?
          Curses::start_color
          Curses::init_pair( Curses::COLOR_BLACK, Curses::COLOR_BLACK, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_RED, Curses::COLOR_RED, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_GREEN, Curses::COLOR_GREEN, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_YELLOW, Curses::COLOR_YELLOW, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_BLUE, Curses::COLOR_BLUE, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_MAGENTA, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_CYAN, Curses::COLOR_CYAN, Curses::COLOR_BLACK )
          Curses::init_pair( Curses::COLOR_WHITE, Curses::COLOR_WHITE, Curses::COLOR_BLACK )
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

      if @settings[ 'context.visible' ]
        if @settings[ 'context.combined' ]
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

      @win_interaction.refresh
      @win_main.refresh
      if @win_line_numbers
        @win_line_numbers.refresh
      end

      @buffers.each_value do |buffer|
        buffer.reset_display
      end
    end

    def getTokenRegexp( hash, arg, match )
      language = match[ 1 ]
      token_class = match[ 2 ]
      case_insensitive = ( match[ 3 ] != nil )
      hash[ language ] = ( hash[ language ] or Hash.new )
      if case_insensitive
        hash[ language ][ token_class ] = Regexp.new( arg, Regexp::IGNORECASE )
      else
        hash[ language ][ token_class ] = Regexp.new arg
      end
    end

    def redraw
      load_configuration
      initializeDisplay
      updateStatusLine
      updateContextLine
      @current_buffer.display
    end

    def main_window_height
      # One line for the status line
      # One line for the input line
      # One line for the context line
      retval = Curses::lines - 2
      if @settings[ "context.visible" ] and not @settings[ "context.combined" ]
        retval = retval - 1
      end
      retval
    end

    def main_window_width
      Curses::cols
    end

    # Display text on the interaction line.
    def setILine( string = "" )
      return  if @testing
      Curses::curs_set 0
      @win_interaction.setpos( 0, 0 )
      @win_interaction.addstr( "%-#{Curses::cols}s" % string )
      @win_interaction.refresh
      Curses::curs_set 1
      string.length
    end

    def set_status_variable( identifier, value )
      @status_vars[ identifier ] = value
    end

    def buildStatusLine( truncation = 0 )
      var_array = Array.new
      @settings[ "status.vars" ].each do |var|
        case var
        when "buffer_number"
          var_array.push bufferToNumber( @current_buffer )
        when "col"
          var_array.push( @current_buffer.last_screen_col + 1 )
        when "filename"
          name = @current_buffer.nice_name
          var_array.push name[ ([ truncation, name.length ].min)..-1 ]
        when "modified"
          if @current_buffer.modified?
            var_array.push @settings[ "status.modified_str" ]
          else
            var_array.push ""
          end
        when "num_buffers"
          var_array.push @buffers.length
        when "num_lines"
          var_array.push @current_buffer.length
        when "row", "line"
          var_array.push( @current_buffer.last_row + 1 )
        when "read_only"
          if @current_buffer.read_only
            var_array.push @settings[ "status.read_only_str" ]
          else
            var_array.push ""
          end
        when "selecting"
          if @current_buffer.changing_selection
            var_array.push @settings[ "status.selecting_str" ]
          else
            var_array.push ""
          end
        when 'selection_mode'
          case @current_buffer.selection_mode
          when :block
            var_array.push 'block'
          else
            var_array.push ''
          end
        when 'session_name'
          var_array.push @session[ 'name' ]
        when "type"
          var_array.push @current_buffer.original_language
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
      rescue ArgumentError => e
        str = "%-#{Curses::cols}s" % "(status line configuration error)"
      end
      str
    end
    protected :buildStatusLine

    def updateStatusLine
      return  if @testing

      str = buildStatusLine
      if str.length > Curses::cols
        str = buildStatusLine( str.length - Curses::cols )
      end
      Curses::curs_set 0
      @win_status.setpos( 0, 0 )
      @win_status.addstr str
      @win_status.refresh
      Curses::curs_set 1
    end

    def updateContextLine
      return  if @testing
      return  if @win_context.nil?

      @context_thread.exit if @context_thread
      @context_thread = Thread.new do ||

        context = @current_buffer.context

        Curses::curs_set 0
        @win_context.setpos( 0, 0 )
        chars_printed = 0
        if context.length > 0
          truncation = [ @settings[ "context.max_levels" ], context.length ].min
          max_length = [
            ( Curses::cols / truncation ) - @settings[ "context.separator" ].length,
            ( @settings[ "context.max_segment_width" ] or Curses::cols )
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
          @win_main.setpos( @current_buffer.last_screen_y, @current_buffer.last_screen_x )
          @win_main.refresh
        end
        Curses::curs_set 1
      end

      @context_thread.priority = -2
    end

    def displayEnqueue( buffer )
      @display_queue_mutex.synchronize do
        @display_queue = buffer
      end
    end

    def displayDequeue
      @display_queue_mutex.synchronize do
        if @display_queue
          Thread.new( @display_queue ) do |b|
            @display_mutex.lock
            @display_mutex.unlock
            b.display
          end
          @display_queue = nil
        end
      end
    end

    def showMessage( message, non_interaction_duration = @settings[ 'interaction.choice_delay' ] )
      terminateMessage

      @message_expiry = Time.now + non_interaction_duration
      @message_thread = Thread.new do
        time_left = @message_expiry - Time.now
        while time_left > 0
          setILine "(#{time_left.round}) #{message}"
          @win_main.setpos( @saved_main_y, @saved_main_x )
          sleep 1
          time_left = @message_expiry - Time.now
        end
        setILine message
        @win_main.setpos( @saved_main_y, @saved_main_x )
      end
    end

    def terminateMessage
      if @message_thread and @message_thread.alive?
        @message_thread.terminate
        @message_thread = nil
      end
    end

    def refreshAll
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