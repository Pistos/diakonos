require 'language_server-protocol'

module Diakonos
  module Lsp
    class Transport
      def initialize(reader_io:, writer_io:)
        @reader = (
          LanguageServer::Protocol::Transport::Io::Reader
          .new(reader_io)
        )
        @writer = (
          LanguageServer::Protocol::Transport::Io::Writer
          .new(writer_io)
        )
      end

      private def close
        @reader.close
        @writer.close
      end

      private def read(&block)
        @reader.read(&block)
      end

      private def write(message:)
        @writer.write(message)
      end
    end
  end
end
