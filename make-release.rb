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
    'LICENCE',
    'CHANGELOG',
    'setup.rb',
    'diakonos.conf',
    'Rakefile',
    'home-on-save.rb',
]

puts "git tag and export..."
doCommand "git tag -a v#{version} -m 'Tagged Diakonos version #{version}.'"
doCommand "git archive --format=tar --prefix=diakonos-#{version}/ refs/tags/v#{version} | bzip2 > diakonos-#{version}.tar.bz2"
doCommand "git archive --format=tar --prefix=diakonos-#{version}/ refs/tags/v#{version} | gzip > diakonos-#{version}.tar.gz"

puts "Building gem..."
doCommand( "gem build gemspecs/diakonos-#{version}.gemspec -v" )

puts "MD5 sums:"
doCommand( "md5sum diakonos-#{version}.gem" )
doCommand( "md5sum diakonos-#{version}.tar.gz" )
doCommand( "md5sum diakonos-#{version}.tar.bz2" )

puts "GPG signing:"
doCommand "gpg --detach-sign --default-key 'Pistos <jesusdoesntlikespammers.6.pistos@geoshell.com>' diakonos-#{version}.gem"
doCommand "gpg --detach-sign --default-key 'Pistos <jesusdoesntlikespammers.6.pistos@geoshell.com>' diakonos-#{version}.tar.gz"
doCommand "gpg --detach-sign --default-key 'Pistos <jesusdoesntlikespammers.6.pistos@geoshell.com>' diakonos-#{version}.tar.bz2"

puts "Copying files to website..."
doCommand( "scp diakonos-#{version}.tar.bz2 diakonos-#{version}.tar.gz diakonos-#{version}.gem diakonos-#{version}.tar.bz2.sig diakonos-#{version}.tar.gz.sig diakonos-#{version}.gem.sig CHANGELOG README ebuild/diakonos-#{version}.ebuild pistos@purepistos.net:/home/pistos/sites/purepistos.net/diakonos/" )
doCommand( "scp diakonos-#{version}.gem pistos@purepistos.net:/home/pistos/svn/purepistos.net/public/gems/" )

puts "Release complete."
puts
puts "Announcement sites:"
puts "1) rubyforge.org"
puts "2) freshmeat.net"
puts "3) ebuild"
puts "4) purepistos.net site"
puts "5) blog.purepistos.net"
puts "6) RAA"
puts "7) http://en.wikipedia.org/wiki/Diakonos"
