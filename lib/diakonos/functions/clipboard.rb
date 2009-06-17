module Diakonos
  module Functions

    def copy_selection
      @clipboard.add_clip @current_buffer.copy_selection
      remove_selection
    end

    def cut_selection
      delete  if @clipboard.add_clip( @current_buffer.copy_selection )
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

    def delete_to_eol
      removed_text = @current_buffer.delete_to_eol
      if removed_text
        @clipboard.add_clip removed_text
      end
    end

    def paste
      @current_buffer.paste @clipboard.clip
    end

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