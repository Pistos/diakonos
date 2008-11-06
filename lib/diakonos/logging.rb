module Diakonos
  class Diakonos
    def log( string )
      @log.puts string
      @log.flush
    end
    
    def debugLog( string )
      @debug.puts( Time.now.strftime( "[%a %H:%M:%S] #{string}" ) )
      @debug.flush
    end
    
    def logBacktrace
      begin
        raise Exception
      rescue Exception => e
        e.backtrace[ 1..-1 ].each do |x|
          debugLog x
        end
      end
    end

  end
end