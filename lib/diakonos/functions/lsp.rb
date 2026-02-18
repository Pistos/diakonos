module Diakonos
  module Functions

    def go_to_definition
      buffer = buffer_current
      session = buffer.lsp_session
      if ! session
        set_iline "No LSP session for this buffer."
      else
        session.go_to_definition(
          buffer:,
          on_result: method(:handle_definition_result),
        )
      end
    end

    def hover
      buffer = buffer_current
      session = buffer.lsp_session
      if ! session
        set_iline "No LSP session for this buffer."
      else
        session.hover(
          buffer:,
          on_result: method(:handle_hover_result),
        )
      end
    end

    private def extract_hover_text(content:)
      case content
      when String
        content
      when Hash
        content[:value] || content['value']
      when Array
        content.map { |c|
          case c
          when String
            c
          when Hash
            c[:value] || c['value']
          end
        }
        .compact
        .join("\n")
      end
    end

    private def handle_definition_result(result)
      if result.is_a?(Hash)
        navigate_to_location(location: result)
      elsif result.is_a?(Array) && ! result.empty?
        if result.size == 1
          navigate_to_location(location: result[0])
        else
          show_definition_list(locations: result)
        end
      else
        set_iline "No definition found."
      end
    end

    private def handle_hover_result(result)
      if result && result[:contents]
        text = extract_hover_text(content: result[:contents])
        if text && ! text.empty?
          show_dock(lines: text.lines.map(&:chomp))
        else
          set_iline "No hover information."
        end
      else
        set_iline "No hover information."
      end
    end

    private def navigate_to_location(location:)
      uri = location[:uri] || location[:targetUri]
      range = location[:range] || location[:targetSelectionRange]
      if uri&.start_with?(Lsp::FILE_URI_PREFIX)
        file_path = uri.delete_prefix(Lsp::FILE_URI_PREFIX)
        open_file(file_path)
        if range
          line = range[:start][:line]
          col = range[:start][:character]
          buffer_current.cursor_to(line, col, Buffer::DO_DISPLAY)
        end
      else
        set_iline "Cannot open URI: #{uri}"
      end
    end

    private def show_definition_list(locations:)
      entries = locations.map { |loc|
        uri = loc[:uri] || loc[:targetUri]
        range = loc[:range] || loc[:targetSelectionRange]
        line = range ? range[:start][:line] : 0
        file_path = uri.delete_prefix(Lsp::FILE_URI_PREFIX)

        "#{file_path}:#{line + 1}"
      }

      with_list_file do |list|
        list.puts entries.join("\n")
      end
      open_list_buffer

      file = get_user_input "Select a definition location. "

      if file
        open_file file
      end
    end

  end
end
