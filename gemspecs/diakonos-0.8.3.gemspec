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
        'lib/diakonos.rb',
        'bin/diakonos',
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