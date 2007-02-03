#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
    s.name = 'diakonos'
    s.version = '0.8.3'
    s.summary = 'A usable console-based text editor.'
    s.description = 'Diakonos is a customizable, usable console-based text editor.'
    s.homepage = 'http://purepistos.net/diakonos'
    s.requirements << 'curses library for Ruby (not in default Ruby install on Debian or FreeBSD; not sufficiently implemented on Windows)'
    s.rubyforge_project = 'diakonos'
    
    #s.author = 'Pistos'
    s.authors = [ 'Pistos' ]
    s.email = 'pistos at purepistos dot net'
    
    #s.platform = Gem::Platform::RUBY
    
    s.files = [
        'CHANGELOG',
        'README',
        'home-on-save.rb',
        'diakonos.conf',
        'bin/diakonos',
        'lib/diakonos.rb',
        'lib/diakonos/array.rb',
        'lib/diakonos/bignum.rb',
        'lib/diakonos/bookmark.rb',
        'lib/diakonos/buffer.rb',
        'lib/diakonos/buffer-hash.rb',
        'lib/diakonos/clipboard.rb',
        'lib/diakonos/ctag.rb',
        'lib/diakonos/enumerable.rb',
        'lib/diakonos/finding.rb',
        'lib/diakonos/fixnum.rb',
        'lib/diakonos/hash.rb',
        'lib/diakonos/keycode.rb',
        'lib/diakonos/object.rb',
        'lib/diakonos/readline.rb',
        'lib/diakonos/regexp.rb',
        'lib/diakonos/sized-array.rb',
        'lib/diakonos/string.rb',
        'lib/diakonos/text-mark.rb',
        'lib/diakonos/window.rb',
    ]
    s.executables = [ 'diakonos' ]
    #s.conf_files = [ 'diakonos.conf' ]
    s.extra_rdoc_files = [ 'README', 'CHANGELOG' ]
    s.test_files = Dir.glob( 'test/*-test.rb' )
    #s.autorequire = 'diakonos'
end

if $PROGRAM_NAME == __FILE__
    Gem::Builder.new( spec ).build
end