module Diakonos

class CTag
    attr_reader :file, :command, :kind, :rest

    def initialize( file, command, kind, rest )
        @file = file
        @command = command
        @kind = kind
        @rest = rest
    end

    def to_s
        "#{@file}:#{@command} (#{@kind}) #{@rest}"
    end

    def == ( other )
        (
            other &&
            @file == other.file &&
            @command == other.command &&
            @kind == other.kind &&
            @rest == other.rest
        )
    end
end

end