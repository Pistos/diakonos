module Diakonos
  class BracketedPaste

    DISABLE_PASTE_SEQ = "\e[?2004l"
    ENABLE_PASTE_SEQ = "\e[?2004h"
    END_SUFFIX = "[201~".chars.map(&:ord).freeze
    ASCII_EXTENDED_END = 255
    ASCII_LAST_CONTROL_CHAR = 31
    QUIESCENCE_SECONDS = 0.02
    START_SUFFIX = "[200~".chars.map(&:ord).freeze

    def disable_paste_mode
      if ! @testing
        $stdout.write(DISABLE_PASTE_SEQ)
        $stdout.flush
      end
    end

    def enable_paste_mode
      if ! @testing
        $stdout.write(ENABLE_PASTE_SEQ)
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
      matched = try_read_start_suffix(window:)

      if matched
        collect(mode:, window:)
      end
    end

    private def append_char(c:, mode:, window:)
      appended = nil

      if c == ENTER
        if mode == 'edit'
          appended = "\n"
        end
      else
        utf_8_char = read_utf_8(byte: c, window:)
        if utf_8_char
          appended = utf_8_char
        elsif typeable?(char: c)
          appended = c
        end
      end

      appended
    end

    private def collect(mode:, window:)
      text = +""

      catch(:paste_done) do
        loop do
          ch = timed_getch(window:)

          if ch.nil?
            throw :paste_done
          end

          c = ch.ord

          if c == ESCAPE
            c = handle_escape_in_paste(window:)
          end

          if c
            to_append = append_char(c:, mode:, window:)
            if to_append
              text << to_append
            end
          end
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
      result = nil

      if end_marker?(window:)
        trailing_ch = timed_getch(window:)
        if trailing_ch.nil?
          throw :paste_done
        end

        result = trailing_ch.ord
      end

      result
    end

    private def read_utf_8(byte:, window:)
      continuation_bytes = utf_8_continuation_byte_count(byte:)

      if continuation_bytes > 0
        remaining = continuation_bytes.times.map {
          window.getch.ord
        }
        byte_array = [byte] + remaining

        byte_array
        .pack('C*')
        .force_encoding('utf-8')
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

    private def try_read_start_suffix(window:)
      chars_read = []
      matched = true

      START_SUFFIX.each do |expected|
        if matched
          ch = timed_getch(window:)

          if ch.nil?
            matched = false
          elsif ch.ord != expected
            chars_read << ch.ord
            matched = false
          else
            chars_read << ch.ord
          end
        end
      end

      if ! matched
        ungetch_chars(chars: chars_read)
      end

      matched
    end

    private def typeable?(char:)
      char > ASCII_LAST_CONTROL_CHAR &&
      char < ASCII_EXTENDED_END &&
      char != BACKSPACE
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
