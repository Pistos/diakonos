module Diakonos
  class Diakonos
    def cursor_stack_remove_buffer( buffer )
      @cursor_stack.delete_if { |frame|
        frame[ :buffer ] == buffer
      }
    end
  end
end