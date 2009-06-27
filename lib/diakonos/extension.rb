module Diakonos

  class Extension

    attr_reader :scripts, :confs

    def initialize( dir )
      @scripts = []
      @confs = []
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

  end

end