module Diakonos
  module Lsp
    class Session
      def initialize(server:)
        @server = server
      end

      def process_queue
        loop do
          message = @server.queue.pop(true)
          handle_message(message:)
        rescue ThreadError
          break
        end
      end

      def stop
        @server.stop
      end

      private def handle_message(message:)
        $diakonos.log("LSP received: #{message}")
      end
    end
  end
end
