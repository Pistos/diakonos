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
        return "#{@file}:#{@command} (#{@kind}) #{@rest}"
    end
    
    def == ( other )
        return (
            other and
            @file == other.file and
            @command == other.command and
            @kind == other.kind and
            @rest == other.rest
        )
    end
end

end