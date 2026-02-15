module Diakonos
  module Lsp
    class Session
      def initialize(server:)
        @pending_requests = {}
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

      def send_notification(method:, params: {})
        @server.write(
          message: {
            method:,
            params:,
          },
        )
      end

      def send_request(method:, params: {})
        request_id = @server.next_request_id
        @pending_requests[request_id] = {
          id: request_id,
          method:,
          sent_at: Time.now,
        }
        @server.write(
          message: {
            id: request_id,
            method:,
            params:,
          },
        )

        request_id
      end

      private def handle_message(message:)
        if message[:id] && ! message[:method]
          handle_response(message:)
        elsif message[:method] && ! message[:id]
          handle_notification(message:)
        elsif message[:method] && message[:id]
          handle_server_request(message:)
        else
          $diakonos.log("LSP: unrecognized message: #{message}")
        end
      end

      private def handle_notification(message:)
        $diakonos.log("LSP notification: #{message[:method]} #{message[:params]}")
      end

      private def handle_response(message:)
        request = @pending_requests.delete(message[:id])
        if request
          $diakonos.log(
            "LSP response for #{request[:method]} (id=#{message[:id]}): #{message[:result]}"
          )
        else
          $diakonos.log(
            "LSP response for unknown request id=#{message[:id]}: #{message[:result]}"
          )
        end
      end

      private def handle_server_request(message:)
        $diakonos.log(
          "LSP server request: #{message[:method]} (id=#{message[:id]}) #{message[:params]}"
        )
      end
    end
  end
end
