#!/usr/bin/env ruby

class String
    def brightRed
        return "\033[1;31m" + self + "\033[0m"
    end
    def brightGreen
        return "\033[1;32m" + self + "\033[0m"
    end
end

def doCommand( command )
    puts command.brightGreen
    puts `#{command}`
    if not $?.nil? and $?.exitstatus > 0
        puts "'#{command}' failed with exit code #{$?}".brightRed
        exit $?
    end
end

if ARGV.length < 1
    puts "#{$0} <version number>"
    exit 1
end

version = ARGV[ 0 ]

Dir.chdir
Dir.chdir( "src" )
puts "Changed to #{Dir.pwd}".brightGreen
doCommand( "svn -m 'Tagging Diakonos version #{version}.' cp http://rome.purepistos.net/svn/diakonos/trunk http://rome.purepistos.net/svn/diakonos/tags/v#{version}" )
doCommand( "svn export http://rome.purepistos.net/svn/diakonos/tags/v#{version} diakonos-#{version}" )
doCommand( "rm -f diakonos-#{version}/make-release.rb" )
doCommand( "tar cjvf diakonos-#{version}.tar.bz2 diakonos-#{version}" )
doCommand( "tar czvf diakonos-#{version}.tar.gz diakonos-#{version}" )
doCommand( "scp diakonos-#{version}.tar.bz2 diakonos-#{version}.tar.gz diakonos-#{version}/CHANGELOG diakonos-#{version}/README pistos@purepistos.net:/home/pistos/www/diakonos" )

puts "Release complete."
puts "Announcement sites:"
puts "1) freshmeat.net"
puts "2) rubyforge.org"
puts "3) purepistos.net site"
puts "4) purepistos.net forums"
puts "5) RAA"
