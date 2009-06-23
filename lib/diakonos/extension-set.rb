module Diakonos

  class ExtensionSet

    def initialize( root_dir )
      @extensions = Hash.new
      @root_dir = File.expand_path( root_dir )
    end

    def scripts
      @extensions.values.map { |e| e.scripts }.flatten
    end

    def parse_version( s )
      if s
        s.split( '.' ).map { |part| part.to_i }.extend( Comparable )
      end
    end

    def load( dir )
      confs_to_parse = []
      ext_dir = File.join( @root_dir, dir )
      info = YAML.load_file( File.join( ext_dir, 'info.yaml' ) )

      if info[ 'diakonos' ]
        this_version = parse_version( ::Diakonos::VERSION )
        min_version = parse_version( info[ 'diakonos' ][ 'minimum' ] )
        if min_version && this_version >= min_version
          extension = Extension.new( ext_dir )
          @extensions[ dir ] = extension
          confs_to_parse += extension.confs
        end
      end

      confs_to_parse
    end

  end

end