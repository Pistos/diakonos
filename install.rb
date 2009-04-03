#!/usr/bin/env ruby

require './lib/diakonos/version.rb'
require 'fileutils'
require 'pp'
require 'rbconfig'

module Diakonos
  class Installer

    def strip_prefix( str )
      str.sub( %r{^#{Regexp.escape( @prefix )}/*}, '' )
    end

    def initialize( argv = ARGV.dup )
      rconfig = RbConfig::CONFIG

      bang_ruby = File.join( rconfig[ 'bindir' ], rconfig[ 'ruby_install_name' ] )
      @shebang = "#!#{bang_ruby}"

      want_help    = false
      @verbose     = false
      @pretend     = false

      @dest_dir    = '/'
      @lib_dir     = nil
      @conf_dir    = nil
      @bin_dir     = nil
      @doc_dir     = nil

      @prefix      = rconfig[ 'prefix' ]
      @bin_suffix  = strip_prefix( rconfig[ 'bindir' ] )
      @lib_suffix  = strip_prefix( rconfig[ 'sitelibdir' ] )
      @conf_dir    = rconfig[ 'sysconfdir' ]
      @doc_suffix  = strip_prefix( rconfig[ 'docdir' ].sub( /\$\(PACKAGE\)/, "diakonos-#{Diakonos::VERSION}" ) )

      while argv.any?
        arg = argv.shift
        case arg
        when '--dest-dir'
          @dest_dir = argv.shift
        when '--prefix'
          @prefix = argv.shift
        when '--bin-dir'
          @bin_dir = argv.shift
        when '--conf-dir'
          @conf_dir = argv.shift
        when '--doc-dir'
          @doc_dir = argv.shift
        when '--lib-dir'
          @lib_dir = argv.shift
        when '-v', '--verbose'
          @verbose = true
        when '-p', '--pretend', '--dry-run'
          @pretend = true
        when '-h', '--help'
          want_help = true
        end
      end

      @bin_dir  ||= File.join( @prefix, @bin_suffix )
      @lib_dir  ||= File.join( @prefix, @lib_suffix )
      @doc_dir  ||= File.join( @prefix, @doc_suffix )

      if want_help
        print_usage_and_exit
      end

      if @pretend
        puts "(Dry run only; not actually writing any files or directories)"
        puts
      end

      if @verbose && @pretend
        self.extend FileUtils::DryRun
      elsif @verbose
        self.extend FileUtils::Verbose
      elsif @pretend
        self.extend FileUtils::NoWrite
      else
        self.extend FileUtils
      end

      @installed_files = []
      @installed_dirs = []
    end

    def print_usage_and_exit
      puts "#{$0} [options]"
      puts "    -h / --help          show usage (can be used with other options to preview paths)"
      puts "    -v / --verbose       print each step"
      puts "    -p / --pretend       don't actually do anything"
      puts "    --prefix <path>      set installation prefix (default #{@prefix})"
      puts "    --dest-dir <path>    set installation sandbox dir (default #{@dest_dir})"
      puts "    --bin-dir <path>     set executable installation dir (default <prefix>/#{@bin_suffix})"
      puts "    --doc-dir <path>     set documentation installation dir (default <prefix>/#{@doc_suffix})"
      puts "    --conf-dir <path>    set configuration installation dir (default #{@conf_dir})"
      puts "    --lib-dir <path>     set library installation dir (default <prefix>/#{@lib_suffix})"
      exit 2
    end

    def write_installation_settings
      installation_file = File.join( @lib_dir, 'diakonos', 'installation.rb' )
      if @verbose
        puts "Writing installation settings to #{installation_file}"
      end
      return  if @pretend

      File.open( installation_file, 'w' ) do |f|
        f.puts %|
module Diakonos
  INSTALL_SETTINGS = {
    :prefix   => #{@prefix.dump},
    :bin_dir  => #{@bin_dir.dump},
    :doc_dir  => #{@doc_dir.dump},
    :help_dir => #{@help_dir.dump},
    :conf_dir => #{@conf_dir.dump},
    :lib_dir  => #{@lib_dir.dump},
    :installed => {
      :files => #{@installed_files.pretty_inspect.strip},
      :dirs => #{@installed_dirs.pretty_inspect.strip},
    },
  }
end
|
      end
    end

    def cp_( source, dest )
      cp source, File.join( @dest_dir, dest )
      Array( source ).each do |file|
        @installed_files << File.expand_path( File.join( dest, File.basename( file ) ) )
      end
    end

    def mkdir_( dir )
      begin
        mkdir_p File.join( @dest_dir, dir ), :mode => 0755
        @installed_dirs << dir
      rescue Errno::EEXIST
        # Don't panic if the directory already exists
      end
    end

    def install_( source, dest )
      dest_file = File.join( dest, File.basename( source ) )
      dest_dir_file = File.join( @dest_dir, dest_file )

      install source, dest_dir_file, :mode => 0755

      # Rewrite shebang line
      command = "sed -i_ '1s|.*|#{@shebang}|' #{dest_dir_file}"

      if @verbose
        puts command
      end
      if ! @pretend
        system command
        rm "#{dest_dir_file}_"
      end

      @installed_files << dest_file
    end

    def run
      # Libraries
      mkdir_ @lib_dir
      cp_ 'lib/diakonos.rb', @lib_dir

      dir = "#{@lib_dir}/diakonos"
      mkdir_ dir
      lib_files = Dir[ 'lib/diakonos/*.rb' ].reject { |f| f =~ /installation\.rb/ }
      cp_ lib_files, dir

      dir = "#{@lib_dir}/diakonos/vendor"
      mkdir_ dir
      cp_ Dir[ 'lib/diakonos/vendor/*.rb' ], dir

      # Configuration
      mkdir_ @conf_dir
      cp_ %w( diakonos.conf diakonos-256-colour.conf ), @conf_dir

      # Executables
      mkdir_ @bin_dir
      install_ 'bin/diakonos', @bin_dir

      # Documentation
      @help_dir = "#{@doc_dir}/help"
      mkdir_ @help_dir
      cp_ %w( README CHANGELOG LICENCE ), @doc_dir
      cp_ Dir[ 'help/*' ], @help_dir

      write_installation_settings
    end
  end
end

installer = Diakonos::Installer.new
installer.run

puts %{
Diakonos #{Diakonos::VERSION} (#{Diakonos::LAST_MODIFIED}) installed.

If Diakonos has been installed with a Linux distro's package manager,
uninstall using that package manager.
If Diakonos has been installed independently of a package manager,
uninstall by running:

  diakonos --uninstall

Thank you for installing Diakonos.  Have a stupendous day!  :)

}
