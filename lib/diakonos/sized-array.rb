class SizedArray < Array
    attr_reader :capacity
    
    def initialize( capacity = 10, *args )
        @capacity = capacity
        super( *args )
    end
    
    def resize
        if size > @capacity
            slice!( (0...-@capacity) )
        end
    end
    private :resize
    
    def concat( other_array )
        super( other_array )
        resize
        return self
    end
    
    def fill( *args )
        retval = super( *args )
        resize
        return self
    end
    
    def <<( item )
        retval = super( item )
        if size > @capacity
            retval = shift
        end
        return retval
    end
    
    def push( item )
        self << item
    end
    
    def unshift( item )
        retval = super( item )
        if size > @capacity
            retval = pop
        end
        return retval
    end
end

