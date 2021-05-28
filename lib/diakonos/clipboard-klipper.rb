module Diakonos

  # Same interface as Diakonos::Clipboard, except interacts with Klipper in KDE 3 (via dcop)
  class ClipboardKlipper

    def initialize
    end

    # Returns true iff some text was copied to klipper.
    def send_to_klipper( text )
      return false  if text.nil?

      clip_filename = write_to_clip_file( text.join( "\n" ) )

      # A little shell sorcery to ensure the shell doesn't strip off trailing newlines.
      `clipping=$(cat #{clip_filename};printf "_"); dcop klipper klipper setClipboardContents "${clipping%_}"`
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
      text = `dcop klipper klipper getClipboardContents`.split( "\n", -1 )
      # getClipboardContents puts an extra newline on end; pop it off.
      text.pop
      text
    end

    # text is an array of Strings
    # Returns true iff a clip was added,
    # and only non-nil text can be added.
    def add_clip( text )
      return false  if text.nil?
      send_to_klipper text
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
      send_to_klipper last_clip + text
    end
  end

end
