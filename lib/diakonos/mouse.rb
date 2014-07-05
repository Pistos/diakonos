module Diakonos
  class Diakonos
    def handle_mouse_event
      event = Curses::getmouse
      return  if event.nil?

      if event.bstate & Curses::BUTTON1_CLICKED > 0
        buffer_current.cursor_to(
          buffer_current.top_line + event.y,
          buffer_current.left_column + event.x,
          Buffer::DO_DISPLAY
        )
      else
        $diakonos.debug_log "button state = #{'0x%x' % event.bstate}, "
      end
    end
  end
end
