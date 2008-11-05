class BufferHash < Hash
    def [] ( key )
        case key
            when String
                key = File.expand_path( key )
        end
        super
    end
    
    def []= ( key, value )
        case key
            when String
                key = File.expand_path( key )
        end
        super
    end
end

