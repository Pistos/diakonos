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

def printUsage
    puts "#{$0} <version number> [--work-dir <dir>] [--step]"
end

# ---------------

if ARGV.length < 1
    printUsage
    exit 1
end

version = nil
work_dir = '/misc/pistos/unpack'
$step = false

args = ARGV.dup
while args.length > 0
    arg = args.shift
    case arg
        when '-h', '--help'
            printUsage
            exit 1
        when '--step'
            $step = true
        when '--work-dir'
            work_dir = args.shift
        else
            version = arg
    end
end

tarball_files = [
    'lib',
    'bin',
    'test',
    'README',
    'CHANGELOG',
    'setup.rb',
    'diakonos.conf',
    'Rakefile',
    'home-on-save.rb',
]

Dir.chdir( work_dir )
puts "Changed to #{Dir.pwd}".brightGreen

puts "git tag and export..."
#doCommand "git tag -a v#{version}"
doCommand "git archive --format=tar --prefix=diakonos-#{version}/ refs/tags/v#{version} | bzip2 > diakonos-#{version}.tar.bz2"
doCommand "git archive --format=tar --prefix=diakonos-#{version}/ refs/tags/v#{version} | gzip > diakonos-#{version}.tar.gz"

puts "Building gem..."
Dir.chdir "diakonos-#{version}"
doCommand( "gem build gemspecs/diakonos-#{version}.gemspec -v" )

puts "Copying files to website..."
Dir.chdir ".."
doCommand( "scp diakonos-#{version}.tar.bz2 diakonos-#{version}.tar.gz diakonos-#{version}/diakonos-#{version}.gem diakonos-#{version}/CHANGELOG diakonos-#{version}/README diakonos-#{version}/ebuild/diakonos-#{version}.ebuild pistos@purepistos.net:/home/pistos/svn/purepistos.net/ramaze/public/diakonos/" )

puts "MD5 sums:"
doCommand( "md5sum diakonos-#{version}/diakonos-#{version}.gem" )
doCommand( "md5sum diakonos-#{version}.tar.gz" )
doCommand( "md5sum diakonos-#{version}.tar.bz2" )

puts "GPG signing:"
doCommand( "gpg --detach-sign diakonos-#{version}/diakonos-#{version}.gem diakonos-#{version}.tar.gz diakonos-#{version}.tar.bz2" )

puts "Release complete."
puts
puts "Announcement sites:"
puts "0) rubyforge.org"
puts "1) freshmeat.net"
puts "2) ebuild, ebuildexchange"
puts "3) purepistos.net site"
puts "4) http://rome.purepistos.net/issues/diakonos/roadmap"
puts "5) purepistos.net forums"
puts "6) RAA"
puts "7) openusability.org"
puts "8) http://en.wikipedia.org/wiki/Diakonos"
