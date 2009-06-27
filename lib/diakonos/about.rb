module Diakonos
  class Diakonos

    def about_write
      File.open( @about_filename, "w" ) do |f|
        inst = ::Diakonos::INSTALL_SETTINGS
        f.puts %{
# About Diakonos

## Version

Version:        #{ ::Diakonos::VERSION }
Code Date:      #{ ::Diakonos::LAST_MODIFIED }
Install Time:   #{ File.mtime( File.join( inst[ :lib_dir ], 'diakonos', 'installation.rb' ) ) }

## Extensions



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