module Diakonos
  module Functions

    # Copies the currently selected text to clipboard then unselects.
    def copy_selection
      @clipboard.add_clip buffer_current.copy_selection
      remove_selection
    end

    # Copies the currently selected text to clipboard, then deletes it.
    def cut_selection
      if @clipboard.add_clip( buffer_current.copy_selection )
        delete
      end
    end

    # Deletes the current line, and adds it to the clipboard.
    # If the previous command was also delete_and_store_line,
    # append the line to the previous clip instead of making
    # a new clip.
    def delete_and_store_line
      removed_text = buffer_current.delete_line
      if removed_text
        clip = [ removed_text, "" ]
        if @last_commands[ -1 ] =~ /^delete_and_store_line/
          @clipboard.append_to_clip clip
        else
          @clipboard.add_clip clip
        end
      end
    end

    # Deletes the text from the current cursor position to the end of the line,
    # then adds the deleted text to the clipboard.
    def delete_to_eol
      removed_text = buffer_current.delete_to_eol
      if removed_text
        @clipboard.add_clip removed_text
      end
    end

    # Pastes the current clipboard item at the current cursor position.
    def paste
      buffer_current.paste @clipboard.clip
    end

    # Opens a new buffer showing a list of all internal clipboard items.
    # Only for use when no external clipboard is used.
    def show_clips
      clip_filename = @diakonos_home + "/clips.txt"
      File.open( clip_filename, "w" ) do |f|
        case @settings[ 'clipboard.external' ]
        when 'klipper'
          f.puts 'Access Klipper directly (tray icon) to get at all clips.'
        when 'xclip'
          f.puts 'xclip does not keep a history of clips.'
        else
          @clipboard.each do |clip|
            f.puts clip
            f.puts "---------------------------"
          end
        end
      end
      open_file clip_filename
    end

  end
end