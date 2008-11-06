module Diakonos
  class Diakonos
    def register_proc( the_proc, hook_name, priority = 0 )
      @hooks[ hook_name ] << { :proc => the_proc, :priority => priority }
    end
    
    def runHookProcs( hook_id, *args )
      @hooks[ hook_id ].each do |hook_proc|
        hook_proc[ :proc ].call( *args )
      end
    end
  end
end