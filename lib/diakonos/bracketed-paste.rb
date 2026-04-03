module Diakonos
  class BracketedPaste

    START_SUFFIX = "[200~".chars.map(&:ord).freeze
    END_SUFFIX = "[201~".chars.map(&:ord).freeze
    QUIESCENCE_SECONDS = 0.02

    def disable_paste_mode
      if ! @testing
        $stdout.write("\e[?2004l")
        $stdout.flush
      end
    end

    def enable_paste_mode
      if ! @testing
        $stdout.write("\e[?2004h")
        $stdout.flush
      end
    end

    def initialize(testing:)
      @testing = testing
    end

    # After ESC has been read from getch, attempt to read the bracketed paste
    # start marker suffix ([200~).  If matched, collect all pasted content
    # until the end marker and return it as a String.
    # Returns nil if this was not a bracketed paste; any chars read are
    # ungetch'd so normal keystroke processing can continue.
    def try_read(mode:, window:)
      chars_read = []

      START_SUFFIX.each do |expected|
        ch = timed_getch(window:)
        if ch.nil?
          ungetch_chars(chars: chars_read)

          return nil
        end
        chars_read << ch.ord
        if ch.ord != expected
          ungetch_chars(chars: chars_read)

          return nil
        end
      end

      collect(mode:, window:)
    end

    private def append_char(c:, mode:, text:, window:)
      if c == ENTER
        text << "\n" if mode == 'edit'
      else
        utf_8_char = read_utf_8(byte: c, window:)
        if utf_8_char
          text << utf_8_char
        elsif typeable?(char: c)
          text << c
        end
      end
    end

    private def collect(mode:, window:)
      text = +""

      catch(:paste_done) do
        loop do
          ch = timed_getch(window:)
          break if ch.nil?

          c = ch.ord

          if c == ESCAPE
            c = handle_escape_in_paste(window:)
            next if c.nil?
          end

          append_char(c:, mode:, text:, window:)
        end
      end

      text.empty? ? nil : text
    end

    private def end_marker?(window:)
      chars_read = []

      matched = END_SUFFIX.all? { |expected|
        ch = timed_getch(window:)
        if ch.nil?
          false
        else
          chars_read << ch.ord
          ch.ord == expected
        end
      }

      if ! matched
        ungetch_chars(chars: chars_read)
      end

      matched
    end

    # When ESC is encountered during paste collection, check whether it
    # begins the end marker.  Returns nil when the caller should skip to
    # the next character (ESC consumed), or returns the ordinal of the
    # next character to process (when a fake end marker was detected and
    # there is trailing input to continue collecting).
    private def handle_escape_in_paste(window:)
      if end_marker?(window:)
        trailing_ch = timed_getch(window:)
        if trailing_ch.nil?
          throw :paste_done
        end

        # Input continued after end marker -- it was injected.
        trailing_ch.ord
      end
    end

    private def read_utf_8(byte:, window:)
      continuation_bytes = utf_8_continuation_byte_count(byte:)
      if continuation_bytes > 0
        byte_array = [byte] + continuation_bytes.times.map { window.getch.ord }

        byte_array.pack('C*').force_encoding('utf-8')
      end
    end

    private def timed_getch(window:)
      ch = nil
      begin
        Timeout.timeout(QUIESCENCE_SECONDS) do
          ch = window.getch
        end
      rescue Timeout::Error
        # no-op
      end

      ch
    end

    private def typeable?(char:)
      char > 31 && char < 255 && char != BACKSPACE
    end

    private def ungetch_chars(chars:)
      chars.reverse_each { |c| Curses.ungetch(c) }
    end

    private def utf_8_continuation_byte_count(byte:)
      if Keying::UTF_8_2_BYTE_BEGIN <= byte && byte <= Keying::UTF_8_2_BYTE_END
        1
      elsif Keying::UTF_8_3_BYTE_BEGIN <= byte && byte <= Keying::UTF_8_3_BYTE_END
        2
      elsif Keying::UTF_8_4_BYTE_BEGIN <= byte && byte <= Keying::UTF_8_4_BYTE_END
        3
      else
        0
      end
    end

  end
end
