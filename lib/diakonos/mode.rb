module Diakonos
  class Mode
    attr_reader :keymap, :window

    def initialize
      @keymap = Hash.new.extend( KeyMap )
    end

    def window=( w )
      @window = w
    end
  end
end