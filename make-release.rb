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
    if $step
        do_it = false
        print "Execute? [y]es, [n]o, yes to [a]ll "; $stdout.flush
        input = $stdin.gets.strip.downcase
        case input
            when 'y'
                do_it = true
            when 'a'
                do_it = true
                $step = false
        end
    else
        do_it = true
    end
    if do_it
        puts `#{command}`
        if not $?.nil? and $?.exitstatus > 0
            puts "'#{command}' failed with exit code #{$?}".brightRed
            exit $?
        end
    else
        puts "(skipping)"
    end
end

if ARGV.length < 1
    puts "#{$0} <version number>"
    exit 1
end

version = ARGV[ 0 ]
$step = ! ARGV[ 1 ].nil?

release_files = [
    'CHANGELOG',
    'diakonos',
    'diakonos.conf',
    'home-on-save.rb',
    'package.rb',
    'README',
    'setup.rb',
]

Dir.chdir
Dir.chdir( "src" )
puts "Changed to #{Dir.pwd}".brightGreen
doCommand( "svn -m 'Tagging Diakonos version #{version}.' cp http://rome.purepistos.net/svn/diakonos/trunk http://rome.purepistos.net/svn/diakonos/tags/v#{version}" )
doCommand( "svn export http://rome.purepistos.net/svn/diakonos/tags/v#{version} diakonos-#{version}" )
doCommand( "tar cjvf diakonos-#{version}.tar.bz2 " + ( release_files.collect { |f| "diakonos-#{version}/#{f}" } ).join( ' ' ) )
doCommand( "tar czvf diakonos-#{version}.tar.gz " + ( release_files.collect { |f| "diakonos-#{version}/#{f}" } ).join( ' ' ) )
doCommand( "scp diakonos-#{version}.tar.bz2 diakonos-#{version}.tar.gz diakonos-#{version}/CHANGELOG diakonos-#{version}/README diakonos-#{version}/ebuild/diakonos-#{version}.ebuild pistos@purepistos.net:/home/pistos/www/diakonos/" )

puts "MD5 sums:"
doCommand( "md5sum diakonos-#{version}.tar.gz" )
doCommand( "md5sum diakonos-#{version}.tar.bz2" )

puts "Release complete."
puts "Announcement sites:"
puts "1) freshmeat.net"
puts "2) ebuild, ebuildexchange"
puts "3) purepistos.net site"
puts "4) http://rome.purepistos.net/issues/diakonos/roadmap"
puts "5) purepistos.net forums"
puts "6) RAA"
puts "7) openusability.org"
puts "8) http://en.wikipedia.org/wiki/Diakonos"
