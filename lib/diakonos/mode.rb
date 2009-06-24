module Diakonos
  class Mode
    attr_reader :keymap

    def initialize
      @keymap = Hash.new.extend( KeyMap )
    end
  end
end