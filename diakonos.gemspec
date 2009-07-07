#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
    s.name = 'diakonos'
    s.version = '0.8.11'
    s.summary = 'A usable console-based text editor.'
    s.description = 'Diakonos is a customizable, usable console-based text editor.'
    s.homepage = 'http://purepistos.net/diakonos'
    s.requirements << 'curses library for Ruby (not in default Ruby install on Debian or FreeBSD)'
    s.rubyforge_project = 'diakonos'

    s.author = 'Pistos'
    s.email = 'pistos at purepistos dot net'

    s.platform = Gem::Platform::RUBY

    s.post_install_message = %{

------------------------------------------------------------------------------
Dear RubyGems administrator:

As of version 0.8.8, Diakonos is no longer installed via RubyGems.  You may
find that a Diakonos package is already available for your operating system's
package manager.  There are packages for: Ubuntu, Debian, Gentoo, Arch Linux,
Slackware, Sourcemage, and possibly more.

If there is no package for your system, you can install Diakonos manually:

- Uninstall any previously installed diakonos gems (including this one)
- Acquire a tarball from http://purepistos.net/diakonos
- Unpack the tarball
- ruby install.rb --help

I apologize for the inconvenience, but the RubyGems system (at the time of this
writing) is much more tailored for libraries rather than full applications like
Diakonos.


Pistos
2009-03-08

}

    s.files = [ ]
end

if $PROGRAM_NAME == __FILE__
    Gem::Builder.new( spec ).build
end