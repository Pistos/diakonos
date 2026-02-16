module Diakonos
  module Lsp
    class Diagnostic
      SEVERITY_LABELS = {
        1 => 'Error',
        2 => 'Warning',
        3 => 'Info',
        4 => 'Hint',
      }.freeze

      def initialize(data:)
        @data = data
      end

      def end_line
        @data[:range][:end][:line]
      end

      def message
        @data[:message]
      end

      def severity
        @data[:severity]
      end

      def severity_label
        SEVERITY_LABELS[severity] || 'Diagnostic'
      end

      def start_line
        @data[:range][:start][:line]
      end

      def to_s
        display_line = start_line + 1

        "L#{display_line}: #{severity_label}: #{message}"
      end
    end
  end
end
