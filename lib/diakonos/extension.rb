module Diakonos

  class Extension

    attr_reader :dir, :scripts, :confs

    def initialize( dir )
      @scripts = []
      @confs = []
      @dir = File.basename( dir )
      @info = YAML.load_file( File.join( dir, 'info.yaml' ) )

      Dir[ File.join( dir, '**', '*.rb' ) ].each do |ext_file|
        @scripts << ext_file
      end

      Dir[ File.join( dir, "*.conf" ) ].each do |conf_file|
        @confs << conf_file
      end
    end

    def []( key )
      @info[ key ]
    end

    [ 'name', 'description', 'version' ].each do |m|
      define_method( m ) do
        @info[ m ]
      end
    end

  end

end