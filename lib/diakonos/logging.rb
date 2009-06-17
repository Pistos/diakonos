module Diakonos

  class Diakonos

    def log( string )
      @log.puts string
      @log.flush
    end

    def debug_log( string )
      @debug.puts( Time.now.strftime( "[%a %H:%M:%S] #{string}" ) )
      @debug.flush
    end

    def log_backtrace
      begin
        raise Exception
      rescue Exception => e
        e.backtrace[ 1..-1 ].each do |x|
          debug_log x
        end
      end
    end

  end

end