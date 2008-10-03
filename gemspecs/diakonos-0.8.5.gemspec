#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
    s.name = 'diakonos'
    s.version = '0.8.5'
    s.summary = 'A Linux editor for the masses.'
    s.description = 'Diakonos is a customizable, usable console-based text editor.'
    s.homepage = 'http://purepistos.net/diakonos'
    s.requirements << 'curses library for Ruby (not in default Ruby install on Debian or FreeBSD; not sufficiently implemented on Windows)'
    s.rubyforge_project = 'diakonos'
    
    s.authors = [ 'Pistos' ]
    s.email = 'pistos at purepistos dot net'
    
    #s.platform = Gem::Platform::RUBY
    
    s.files = [
        'CHANGELOG',
        'README',
        'LICENCE',
        'home-on-save.rb',
        'diakonos.conf',
        'diakonos-256-colour.conf',
        'bin/diakonos',
        'lib/diakonos.rb',
        *( Dir[ 'lib/diakonos/*.rb' ] )
    ]
    s.executables = [ 'diakonos' ]
    s.extra_rdoc_files = [ 'README', 'CHANGELOG', 'LICENCE', ]
    s.test_files = Dir.glob( 'test/*-test.rb' )
end

if $PROGRAM_NAME == __FILE__
    Gem::Builder.new( spec ).build
end