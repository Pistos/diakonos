#!/usr/bin/env ruby

def doCommand( command )
    puts command
    puts `#{command}`
    if $?
        puts "'#{command}' failed with exit code #{$?}"
        exit $?
    end
end

if ARGV.length < 1
    puts "#{$0} <version number>"
    exit 1
end

version = ARGV[ 0 ]

doCommand( "cd ~/src" )
doCommand( "svn cp http://rome.purepistos.net/svn/diakonos/trunk http://rome.purepistos.net/svn/diakonos/tags/v#{version}" )
doCommand( "svn export http://rome.purepistos.net/svn/diakonos/tags/v#{version} diakonos-#{version}" )
doCommand( "rm -f diakonos-#{version}/make-release.rb" )
doCommand( "tar cjvf diakonos-#{version}.tar.bz2 diakonos-#{version}" )
doCommand( "tar czvf diakonos-#{version}.tar.gz diakonos-#{version}" )
doCommand( "scp diakonos-#{version}.tar.bz2 diakonos-#{version}.tar.gz diakonos-#{version}/CHANGELOG diakonos-#{version}/README pistos@purepistos.net:/home/pistos/www/diakonos" )

puts "Release complete."
puts "Announcement sites:"
puts "1) freshmeat.net"
puts "2) rubyforge.org"
puts "3) purepistos.net"