#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_SizedArray < Test::Unit::TestCase
    def test_initialize
        a = SizedArray.new( 2 )
        assert_equal( 2, a.capacity )
        a = SizedArray.new( 4 )
        assert_equal( 4, a.capacity )
    end
    
    def test_append
        a = SizedArray.new( 2 )
        
        assert_equal(
            [ 1 ],
            a << 1
        )
        assert_equal(
            [ 1, 2 ],
            a << 2
        )
        assert_equal(
            1,
            a << 3
        )
        assert_equal(
            [ 2, 3 ],
            a
        )
        assert_equal(
            2,
            a << 1
        )
        assert_equal(
            [ 3, 1 ],
            a
        )
    end
    
    def test_push
        a = SizedArray.new( 2 )
        b = SizedArray.new( 2 )
        
        assert_equal( a, b )
        
        a << 1
        b.push 1
        assert_equal( a, b )
        a << 2
        b.push 2
        assert_equal( a, b )
        a << 3
        b.push 3
        assert_equal( a, b )
    end
    
    def test_unshift
        a = SizedArray.new( 2 )
        
        assert_equal(
            [ 1 ],
            a.unshift( 1 )
        )
        assert_equal(
            [ 2, 1 ],
            a.unshift( 2 )
        )
        assert_equal(
            1,
            a.unshift( 3 )
        )
        assert_equal(
            [ 3, 2 ],
            a
        )
        assert_equal(
            2,
            a.unshift( 1 )
        )
        assert_equal(
            [ 1, 3 ],
            a
        )
    end
    
    def test_concat
        a = SizedArray.new( 4 )
        
        assert_equal(
            [ 1, 2 ],
            a.concat( [ 1, 2 ] )
        )
        assert_equal(
            [ 1, 2, 3, 4 ],
            a.concat( [ 3, 4 ] )
        )
        assert_equal(
            [  3, 4, 5, 6 ],
            a.concat( [ 5, 6 ] )
        )
        assert_equal(
            [  7, 8, 9, 10 ],
            a.concat( [ 7, 8, 9, 10 ] )
        )
        assert_equal(
            [  3, 4, 5, 6 ],
            a.concat( [ 1, 2, 3, 4, 5, 6 ] )
        )
    end
end