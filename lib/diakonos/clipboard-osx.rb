module Diakonos

  # Same interface as Diakonos::Clipboard, except interacts with pbcopy and
  # pbpaste on OSX
  class ClipboardOSX

    def initialize
    end

    # @return true iff some text was copied to pbcopy
    def send_to_pbcopy(text)
      return false  if text.nil?

      clip_filename = write_to_clip_file( text.join( "\n" ) )
      `pbcopy < #{clip_filename}`

      true
    end

    # TODO: DRY this up with other Clipboard classes
    def write_to_clip_file(text)
      clip_filename = $diakonos.diakonos_home + "/clip.txt"
      File.open( clip_filename, "w" ) do |f|
        f.print text
      end
      clip_filename
    end

    # ------------------------------

    def clip
      `pbpaste`.split( "\n", -1 )
    end

    # @param [Array<String>] text
    # @return true iff a clip was added
    def add_clip(text)
      send_to_pbcopy text
    end

    # no-op
    def each
    end

    # @param [Array<String>] lines of text
    # Appends the lines to the current clip.
    # If no current clip, then a new clip is created.
    # @return true iff the text was successfully appended
    def append_to_clip(text)
      return false  if text.nil?

      last_clip = clip
      last_clip.pop  if last_clip[-1] == ""

      send_to_pbcopy  last_clip + text
    end
  end

end
