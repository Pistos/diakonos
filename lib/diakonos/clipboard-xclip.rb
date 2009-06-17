module Diakonos

  # Same interface as Diakonos::Clipboard, except interacts with xclip
  class ClipboardXClip

    def initialize
    end

    # Returns true iff some text was copied to xclip.
    def send_to_xclip( text )
      return false  if text.nil?
      clip_filename = write_to_clip_file( text.join( "\n" ) )
      t = Thread.new do
        `xclip -i #{clip_filename}`
      end
      `xclip -o`  # Unfreeze xclip
      t.terminate
      true
    end

    def write_to_clip_file( text )
      clip_filename = $diakonos.diakonos_home + "/clip.txt"
      File.open( clip_filename, "w" ) do |f|
        f.print text
      end
      clip_filename
    end

    # ------------------------------

    def clip
      `xclip -o`.split( "\n", -1 )
    end

    # text is an array of Strings
    # Returns true iff a clip was added,
    # and only non-nil text can be added.
    def add_clip( text )
      return false  if text.nil?
      send_to_xclip text
    end

    # no-op.
    def each
    end

    # text is an array of Strings (lines)
    # Appends the lines to the current clip.
    # If no current clip, then a new clip is created.
    # Returns true iff the text was successfully appended.
    def append_to_clip( text )
      return false  if text.nil?

      last_clip = clip
      last_clip.pop  if last_clip[ -1 ] == ""
      send_to_xclip last_clip + text
    end
  end

end
