module Diakonos
  module Functions

    def copy_selection
      @clipboard.add_clip @current_buffer.copy_selection
      remove_selection
    end

    def copy_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        remove_selection
      end
    end

    def cut_selection
      delete  if @clipboard.add_clip( @current_buffer.copy_selection )
    end

    def cut_selection_to_klipper
      if send_to_klipper( @current_buffer.selected_text )
        delete
      end
    end

    def delete_and_store_line_to_klipper
      removed_text = @current_buffer.delete_line
      if removed_text
        if @last_commands[ -1 ] =~ /^delete_and_store_line_to_klipper/
          new_clip = escape_quotes( `dcop klipper klipper getClipboardContents`.chomp + removed_text + "\n" )
          `dcop klipper klipper setClipboardContents '#{new_clip}'`
        else
          send_to_klipper [ removed_text, "" ]
        end
      end
    end

    def delete_and_store_line
      removed_text = @current_buffer.delete_line
      if removed_text
        clip = [ removed_text, "" ]
        if @last_commands[ -1 ] =~ /^delete_and_store_line/
          @clipboard.append_to_clip clip
        else
          @clipboard.add_clip clip
        end
      end
    end

    def delete_line_to_klipper
      removed_text = @current_buffer.delete_line
      if removed_text
        send_to_klipper [ removed_text, "" ]
      end
    end

    def delete_to_eol_to_klipper
      removed_text = @current_buffer.delete_to_eol
      if removed_text
        send_to_klipper removed_text
      end
    end

    def delete_to_eol
      removed_text = @current_buffer.delete_to_eol
      @clipboard.add_clip( removed_text ) if removed_text
    end

    def paste
      @current_buffer.paste @clipboard.clip
    end

    def paste_from_klipper
      text = `dcop klipper klipper getClipboardContents`.split( "\n", -1 )
      text.pop  # getClipboardContents puts an extra newline on end
      @current_buffer.paste text
    end

  end
end