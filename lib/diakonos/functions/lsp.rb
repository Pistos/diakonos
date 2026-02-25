module Diakonos
  module Functions

    def complete_code
      session = buffer_current.lsp_session

      if ! session
        set_iline "No LSP session for this buffer."
      else
        trigger_buffer = buffer_current
        trigger_col = buffer_current.last_col
        trigger_prefix = buffer_current.word_before_cursor
        trigger_row = buffer_current.last_row

        session.complete(
          buffer: buffer_current,
          on_response: ->(result) {
            handle_completion_result(
              result:,
              trigger_buffer:,
              trigger_col:,
              trigger_prefix:,
              trigger_row:,
            )
          },
        )
      end
    end

    def go_to_definition
      session = buffer_current.lsp_session

      if ! session
        set_iline "No LSP session for this buffer."
      else
        session.go_to_definition(
          buffer: buffer_current,
          on_response: method(:handle_definition_result),
        )
      end
    end

    def hover
      session = buffer_current.lsp_session

      if ! session
        set_iline "No LSP session for this buffer."
      else
        session.hover(
          buffer: buffer_current,
          on_response: method(:handle_hover_result),
        )
      end
    end

    private def completion_context_valid?(
      trigger_buffer:,
      trigger_prefix:,
      trigger_row:
    )
      buffer_current == trigger_buffer &&
      buffer_current.last_row == trigger_row && (
        buffer_current
        .word_before_cursor
        &.start_with?(trigger_prefix.to_s)
      )
    end

    private def completion_text_for(item:)
      item[:insertText] || item[:label]
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

    private def filter_completion_items(items:, prefix:)
      if prefix.nil? || prefix.empty?
        items
      else
        items.select { |item|
          item[:label]
          &.downcase
          &.start_with?(prefix.downcase)
        }
      end
    end

    private def handle_completion_result(
      result:,
      trigger_buffer:,
      trigger_col:,
      trigger_prefix:,
      trigger_row:
    )
      if completion_context_valid?(trigger_buffer:, trigger_prefix:, trigger_row:)
        items = Array(
          result.respond_to?(:key) ?
          result[:items] :
          result
        )

        if items.empty?
          set_iline "No completions."
        else
          filtered_items = filter_completion_items(items:, prefix: trigger_prefix)

          if filtered_items.empty?
            set_iline "No matching completions."
          else
            show_completion_list(
              items: filtered_items,
              trigger_col:,
              trigger_prefix:,
              trigger_row:,
            )
          end
        end
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

    private def insert_completion(
      item:,
      trigger_col:,
      trigger_prefix:,
      trigger_row:
    )
      text = completion_text_for(item:)
      prefix_len = trigger_prefix.to_s.length
      prefix_start_col = trigger_col - prefix_len

      buffer_current.cursor_to(trigger_row, prefix_start_col, Buffer::DONT_DISPLAY)
      buffer_current.delete_from_to(
        trigger_row, prefix_start_col,
        trigger_row, trigger_col,
      )
      buffer_current.insert_string(text)
      buffer_current.cursor_to(
        trigger_row,
        prefix_start_col + text.length,
        Buffer::DO_DISPLAY,
      )
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

    private def show_completion_list(
      items:,
      trigger_col:,
      trigger_prefix:,
      trigger_row:
    )
      entries = items.map { |item| item[:label] }

      with_list_file do |list|
        list.puts entries.join("\n")
      end
      open_list_buffer

      selection = get_user_input "Select a completion. "

      if selection
        selected_item = items.find { |item| item[:label] == selection }
        if selected_item
          insert_completion(
            item: selected_item,
            trigger_col:,
            trigger_prefix:,
            trigger_row:,
          )
        end
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
