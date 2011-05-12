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

puts "git tag and export..."
doCommand "git tag -a v#{version} -m 'Tagged Diakonos version #{version}.'"
doCommand "git archive --format=tar --prefix=diakonos-#{version}/ refs/tags/v#{version} | bzip2 > diakonos-#{version}.tar.bz2"
doCommand "git archive --format=tar --prefix=diakonos-#{version}/ refs/tags/v#{version} | gzip > diakonos-#{version}.tar.gz"

puts "MD5 sums:"
doCommand( "md5sum diakonos-#{version}.tar.gz" )
doCommand( "md5sum diakonos-#{version}.tar.bz2" )

puts "Copying files to website..."
doCommand( "scp diakonos-#{version}.tar.bz2 diakonos-#{version}.tar.gz CHANGELOG README.rdoc pistos@diakonos.pist0s.ca:/var/www/diakonos.pist0s.ca/archives" )

puts "Release complete."
puts
puts "Announcement sites:"
puts "1) rubyforge.org"
puts "4) diakonos.pist0s.ca"
puts "5) blog.purepistos.net"
puts "6) RAA"
puts "7) http://en.wikipedia.org/wiki/Diakonos"
