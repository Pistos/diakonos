module Diakonos
  class Diakonos

    def about_write
      File.open( @about_filename, "w" ) do |f|
        inst = ::Diakonos::INSTALL_SETTINGS

        configs = @configs.map(&:to_s).join("\n")

        ext_loaded = @extensions.loaded_extensions.sort_by { |e|
          e.name.downcase
        }.map { |e|
          %{
### #{e.name} #{e.version}
#{e.description}
          }.strip
        }.join( "\n\n" )

        ext_not_loaded = @extensions.not_loaded_extensions.sort.map { |e|
          "### #{e} (NOT LOADED)"
        }.join( "\n" )

        installation_artifact = File.join(inst[:lib_dir], 'diakonos', 'installation.rb')
        if File.exist?(installation_artifact)
          install_time = File.mtime(installation_artifact)
        else
          install_time = "--"
        end

        f.puts %{
# About Diakonos

Licence:        MIT Licence
Copyright:      Copyright (c) 2004-#{ Time.now.year } Pistos

## Version

Version:        #{ ::Diakonos::VERSION }
Code Date:      #{ ::Diakonos::LAST_MODIFIED }
Install Time:   #{ install_time }
Ruby Version:   #{ ::RUBY_VERSION }

## Paths

Home dir:       #{ @diakonos_home }

### Installation

Prefix:             #{ inst[ :prefix ] }
Executable dir:     #{ inst[ :bin_dir ] }
Help dir:           #{ inst[ :help_dir ] }
System config dir:  #{ inst[ :conf_dir ] }
System library dir: #{ inst[ :lib_dir ] }

### Configuration Files

#{ configs }

## Extensions

#{ ext_loaded }

#{ ext_not_loaded }
        }.strip
      end
    end

  end
end
