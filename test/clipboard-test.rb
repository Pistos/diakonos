#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos/clipboard'

class TC_Clipboard < Test::Unit::TestCase
    def test_01_addClip
        c = Diakonos::Clipboard.new( 3 )
        assert_equal false, c.addClip( nil )
        assert_equal true, c.addClip( [ 'foo' ] )
        assert_equal true, c.addClip( [ 'bar' ] )
        assert_equal true, c.addClip( [ 'baz' ] )
        assert_equal [ 'foo' ], c[ 2 ]
        assert_nil c[ 3 ]
        assert_equal true, c.addClip( [ 'fiz' ] )
        assert_equal [ 'bar' ], c[ 2 ]
        assert_nil c[ 3 ]
    end
    
    def test_02_brackets
        c = Diakonos::Clipboard.new( 3 )
        assert_nil c[ -1 ]
        assert_nil c[ 0 ]
        assert_nil c[ 1 ]
        assert_equal false, c.addClip( nil )
        x = [ 'foo' ]
        assert_equal true, c.addClip( x )
        assert_equal x, c[ -1 ]
        assert_equal x, c[ 0 ]
        assert_nil c[ 1 ]
    end
    
    def test_03_each
        c = Diakonos::Clipboard.new( 10 )
        9.downto( 0 ) do |i|
            c.addClip( [ i.to_s ] )
        end
        i = 0
        c.each do |clip|
            assert_equal( [ i.to_s ], clip )
            i += 1
        end
    end
    
    def test_04_appendToClip
        c = Diakonos::Clipboard.new( 10 )
        assert_equal false, c.appendToClip( nil )
        x = [ 'foo' ]
        assert_equal true, c.appendToClip( x )
        assert_equal(
            [ 'foo' ],
            c.clip
        )
        
        assert_equal true, c.appendToClip( [ 'bar', 'baz' ] )
        assert_equal(
            [ 'foo', 'bar', 'baz' ],
            c.clip
        )
        
        y = [ 'line with newline', '' ]
        assert_equal true, c.addClip( y )
        assert_equal y, c.clip
        assert_equal true, c.appendToClip( [ 'another line' ] )
        assert_equal(
            [ 'line with newline', 'another line' ],
            c.clip
        )
    end
end