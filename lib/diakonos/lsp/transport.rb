require 'json'
require 'language_server-protocol'

module Diakonos
  module Lsp
    class Transport
      def initialize(reader_io:, writer_io:)
        @reader_io = reader_io
        @reader = (
          LanguageServer::Protocol::Transport::Io::Reader
          .new(reader_io)
        )
        @writer = (
          LanguageServer::Protocol::Transport::Io::Writer
          .new(writer_io)
        )
      end

      def close
        @reader.close
        @writer.close
      end

      def read(&block)
        @reader.read(&block)
      end

      # Reads exactly one LSP message from the reader IO and returns it.
      # Returns nil on EOF.
      def read_one
        buffer = @reader_io.gets("\r\n\r\n")
        if buffer
          content_length = buffer[/Content-Length: (\d+)/i, 1].to_i
          message = @reader_io.read(content_length)
          if message.nil?
            raise 'Unexpected EOF reading LSP message body'
          end

          JSON.parse(message, symbolize_names: true)
        end
      end

      def write(message:)
        @writer.write(message)
      end
    end
  end
end
