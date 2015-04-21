module Diakonos
  class ConfigFile
    attr_reader :filename, :including_filename

    def initialize(filename, including_filename)
      @filename, @including_filename = filename, including_filename
    end
  end
end
