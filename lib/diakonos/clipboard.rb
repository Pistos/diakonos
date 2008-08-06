module Diakonos
  
  class Clipboard
    def initialize( max_clips )
      @clips = Array.new
      @max_clips = max_clips
    end
    
    def [] ( arg )
      return @clips[ arg ]
    end
    
    def clip
      return @clips[ 0 ]
    end
    
    # text is an array of Strings
    # Returns true iff a clip was added,
    # and only non-nil text can be added.
    def addClip( text )
      return false if text == nil
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
    def appendToClip( text )
      return false if text.nil?
      return addClip( text ) if @clips.length == 0
      last_clip = @clips[ 0 ]
      last_clip.pop if last_clip[ -1 ] == ""
      @clips[ 0 ] = last_clip + text
      return true
    end
  end
  
end