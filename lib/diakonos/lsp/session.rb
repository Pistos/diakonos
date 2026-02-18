module Diakonos
  module Lsp
    class Session
      INITIAL_VERSION = 1

      def initialize(on_diagnostics: nil, server:)
        @diagnostics = {}
        @document_versions = {}
        @on_diagnostics = on_diagnostics
        @pending_requests = {}
        @server = server
      end

      def hover(buffer:, on_result:)
        send_request(
          method: 'textDocument/hover',
          on_response: on_result,
          params: {
            position: {
              character: buffer.last_col,
              line: buffer.last_row,
            },
            textDocument: {
              uri: buffer.lsp_uri,
            },
          },
        )
      end

      def go_to_definition(buffer:, on_result:)
        send_request(
          method: 'textDocument/definition',
          on_response: on_result,
          params: {
            position: {
              character: buffer.last_col,
              line: buffer.last_row,
            },
            textDocument: {
              uri: buffer.lsp_uri,
            },
          },
        )
      end

      def diagnostics_for_line(uri:, line:)
        Array(
          @diagnostics[uri]&.select { |d|
            d.start_line <= line && line <= d.end_line
          }
        )
      end

      def notify_did_change(buffer:)
        uri = buffer.lsp_uri
        if @document_versions.key?(uri)
          @document_versions[uri] += 1
          send_notification(
            method: 'textDocument/didChange',
            params: {
              textDocument: {
                uri:,
                version: @document_versions[uri],
              },
              contentChanges: [
                { text: buffer.lines.join("\n") },
              ],
            },
          )
        end
      end

      def notify_did_close(buffer:)
        uri = buffer.lsp_uri
        if @document_versions.key?(uri)
          @document_versions.delete(uri)
          send_notification(
            method: 'textDocument/didClose',
            params: {
              textDocument: { uri: },
            },
          )
        end
      end

      def notify_did_open(buffer:)
        uri = buffer.lsp_uri
        if uri
          @document_versions[uri] = INITIAL_VERSION
          send_notification(
            method: 'textDocument/didOpen',
            params: {
              textDocument: {
                languageId: buffer.original_language,
                text: buffer.lines.join("\n"),
                uri:,
                version: INITIAL_VERSION,
              },
            },
          )
        end
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

      def send_request(method:, on_response: nil, params: {})
        request_id = @server.next_request_id
        @pending_requests[request_id] = {
          id: request_id,
          method:,
          on_response:,
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
        method = message[:method]
        params = message[:params]
        $diakonos.log("LSP notification: #{method} #{params}")
        case method
        when 'textDocument/publishDiagnostics'
          store_diagnostics(params:)
        end
      end

      private def store_diagnostics(params:)
        uri = params[:uri]
        if uri
          raw_diagnostics = params[:diagnostics] || []
          @diagnostics[uri] = raw_diagnostics.map { |data| Diagnostic.new(data:) }
          @on_diagnostics&.call(uri:)
        end
      end

      private def handle_response(message:)
        request = @pending_requests.delete(message[:id])
        if request
          $diakonos.log(
            "LSP response for #{request[:method]} (id=#{message[:id]}): #{message[:result]}"
          )
          request[:on_response]&.call(message[:result])
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
