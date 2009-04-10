module Diakonos

  class Clipboard
    def initialize( max_clips )
      @clips = Array.new
      @max_clips = max_clips
    end

    def [] ( arg )
      @clips[ arg ]
    end

    def clip
      @clips[ 0 ]
    end

    # text is an array of Strings
    # Returns true iff a clip was added,
    # and only non-nil text can be added.
    def add_clip( text )
      return false if text.nil?
      @clips.unshift text
      @clips.pop if @clips.length > @max_clips
      true
    end

    def each
      @clips.each do |clip|
        yield clip
      end
    end

    # text is an array of Strings (lines)
    # Appends the lines to the current clip.
    # If no current clip, then a new clip is created.
    # Returns true iff the text was successfully appended.
    def append_to_clip( text )
      return false if text.nil?
      return add_clip( text ) if @clips.length == 0
      last_clip = @clips[ 0 ]
      last_clip.pop if last_clip[ -1 ] == ""
      @clips[ 0 ] = last_clip + text
      true
    end
  end

end