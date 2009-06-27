module Diakonos
  class Diakonos

    def about_write
      File.open( @about_filename, "w" ) do |f|
        inst = ::Diakonos::INSTALL_SETTINGS
        ext_loaded = @extensions.loaded_extensions.map { |e| "- #{e}" }.sort.join( "\n" )
        ext_broken = @extensions.broken_extensions.map { |e| "- #{e}" }.sort.join( "\n" )

        f.puts %{
# About Diakonos

Licence:        MIT Licence
Copyright:      Copyright (c) 2004-#{ Time.now.year } Pistos

## Version

Version:        #{ ::Diakonos::VERSION }
Code Date:      #{ ::Diakonos::LAST_MODIFIED }
Install Time:   #{ File.mtime( File.join( inst[ :lib_dir ], 'diakonos', 'installation.rb' ) ) }

## Extensions

### Loaded

#{ext_loaded}

### Broken

#{ ! ext_broken.empty? ? ext_broken : '(none)' }

## Paths

Home dir:       #{ @diakonos_home }

### Installation

Prefix:             #{ inst[ :prefix ] }
Executable dir:     #{ inst[ :bin_dir ] }
Help dir:           #{ inst[ :help_dir ] }
System config dir:  #{ inst[ :conf_dir ] }
System library dir: #{ inst[ :lib_dir ] }
        }.strip
      end
    end

  end
end