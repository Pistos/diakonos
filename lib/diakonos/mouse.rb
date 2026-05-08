module Diakonos
  class Diakonos
    def handle_mouse_event
      event = Curses.getmouse
      return  if event.nil?

      if event.bstate & Curses::BUTTON1_CLICKED > 0
        position = buffer_current.buffer_position_at_screen(
          screen_y: event.y,
          screen_x: event.x,
        )
        buffer_current.cursor_to(
          position[ :row ],
          position[ :col ],
          Buffer::DO_DISPLAY
        )
      else
        $diakonos.debug_log "button state = #{'0x%x' % event.bstate}, "
      end
    end
  end
end
