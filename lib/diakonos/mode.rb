module Diakonos
  class Mode
    attr_reader :keymap, :keymap_after, :window

    def initialize
      @keymap = Hash.new.extend( KeyMap )
      # keys of @keymap_after are Strings of Diakonos functions
      @keymap_after = Hash.new { |h,k|
        h[k] = Hash.new.extend( KeyMap )
      }
    end

    def window=( w )
      @window = w
    end
  end
end
