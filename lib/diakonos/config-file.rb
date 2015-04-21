module Diakonos
  # Should inheritance be used in this file instead?

  module ConfigFileDescription
    def to_s
      "#{@filename}\t(#{self.inclusion_description})"
    end

    def name_as_includer
      @filename
    end

    def inclusion_description
      "included by #{@including_config_file.name_as_includer}"
    end
  end

  class ConfigFile
    attr_reader :filename
    attr_accessor :problems

    include ConfigFileDescription

    def initialize(filename, including_config_file)
      @filename, @including_config_file = filename, including_config_file
      @problems = []
    end

    def ==(other_config_file)
      @filename == other_config_file.filename
    end

    def each_line_with_index
      IO.readlines(@filename).each_with_index do |line, line_number|
        yield line, line_number
      end
    end
  end

  class ConfigFileUnreadable
    include ConfigFileDescription

    def initialize(filename, including_config_file)
      @filename, @including_config_file = filename, including_config_file
    end

    def problems
      ["Configuration file #{self} was not found"]
    end

    def each_line_with_index
    end
  end

  class ConfigFileNull
    include ConfigFileDescription

    def name_as_includer
      "Diakonos"
    end
  end
end
