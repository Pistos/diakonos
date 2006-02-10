#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_Hash < Test::Unit::TestCase
    def test_deleteKeyPath
        g = {}
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [] )
        )
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [ 'test' ] )
        )
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [ 'test', 'test2' ] )
        )
        
        g = { 'a' => 'x' }
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.deleteKeyPath( [] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.deleteKeyPath( [ 'test' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.deleteKeyPath( [ 'test', 'test2' ] )
        )
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [ 'a' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.deleteKeyPath( [ 'a', 'b' ] )
        )
        
        g = {
            'a' => {
                'b' => 'x'
            }
        }
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [ 'z' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [ 'z', 'zz' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [ 'a', 'b', 'c' ] )
        )
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [ 'a' ] )
        )
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [ 'a', 'b' ] )
        )
        
        g = {
            'a' => {
                'b' => 'x',
                'c' => 'y'
            }
        }
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x', 'c' => 'y' } },
            h.deleteKeyPath( [] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x', 'c' => 'y' } },
            h.deleteKeyPath( [ 'z' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x', 'c' => 'y' } },
            h.deleteKeyPath( [ 'z', 'zz' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x', 'c' => 'y' } },
            h.deleteKeyPath( [ 'a', 'b', 'c' ] )
        )
        h = g.deep_clone
        assert_equal(
            {},
            h.deleteKeyPath( [ 'a' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'c' => 'y' } },
            h.deleteKeyPath( [ 'a', 'b' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [ 'a', 'c' ] )
        )
        
        g = {
            'a' => {
                'b' => 'x'
            },
            'c' => {
                'd' => 'y'
            }
        }
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } },
            h.deleteKeyPath( [] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } },
            h.deleteKeyPath( [ 'z' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } },
            h.deleteKeyPath( [ 'z', 'zz' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } },
            h.deleteKeyPath( [ 'a', 'b', 'c' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'c' => { 'd' => 'y' } },
            h.deleteKeyPath( [ 'a' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [ 'c' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'c' => { 'd' => 'y' } },
            h.deleteKeyPath( [ 'a', 'b' ] )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.deleteKeyPath( [ 'c', 'd' ] )
        )
    end
    
    def test_setKeyPath
        g = {}
        h = g.deep_clone
        assert_equal(
            {},
            h.setKeyPath( [], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.setKeyPath( [ 'a' ], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.setKeyPath( [ 'a', 'b' ], 'x' )
        )
        
        g = { 'a' => 'x' }
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.setKeyPath( [], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.setKeyPath( [ 'a' ], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.setKeyPath( [ 'a', 'b' ], 'x' )
        )
        
        g = { 'c' => 'y' }
        h = g.deep_clone
        assert_equal(
            { 'c' => 'y' },
            h.setKeyPath( [], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'c' => 'y', 'a' => 'x' },
            h.setKeyPath( [ 'a' ], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'c' => 'y', 'a' => { 'b' => 'x' } },
            h.setKeyPath( [ 'a', 'b' ], 'x' )
        )
        
        g = { 'a' => { 'b' => 'x' } }
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' } },
            h.setKeyPath( [], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => 'x' },
            h.setKeyPath( [ 'a' ], 'x' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' }, 'c' => 'y' },
            h.setKeyPath( [ 'c' ], 'y' )
        )
        h = g.deep_clone
        assert_equal(
            { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } },
            h.setKeyPath( [ 'c', 'd' ], 'y' )
        )
    end
    
    def test_getNode
        h = {}
        assert_equal(
            nil,
            h.getNode( [] )
        )
        assert_equal(
            nil,
            h.getNode( [ 'a' ] )
        )
        assert_equal(
            nil,
            h.getNode( [ 'a', 'b' ] )
        )
        
        h = { 'a' => 'x' }
        assert_equal(
            nil,
            h.getNode( [] )
        )
        assert_equal(
            nil,
            h.getNode( [ 'b' ] )
        )
        assert_equal(
            'x',
            h.getNode( [ 'a' ] )
        )
        
        h = { 'a' => { 'b' => 'x' } }
        assert_equal(
            nil,
            h.getNode( [] )
        )
        assert_equal(
            nil,
            h.getNode( [ 'b' ] )
        )
        assert_equal(
            { 'b' => 'x' },
            h.getNode( [ 'a' ] )
        )
        assert_equal(
            nil,
            h.getNode( [ 'a', 'b', 'c' ] )
        )
        assert_equal(
            nil,
            h.getNode( [ 'a', 'c' ] )
        )
        assert_equal(
            'x',
            h.getNode( [ 'a', 'b' ] )
        )
    end
    
    def test_getLeaf
        h = {}
        assert_equal(
            nil,
            h.getLeaf( [] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'a' ] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'a', 'b' ] )
        )
        
        h = { 'a' => 'x' }
        assert_equal(
            nil,
            h.getLeaf( [] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'b' ] )
        )
        assert_equal(
            'x',
            h.getLeaf( [ 'a' ] )
        )
        
        h = { 'a' => { 'b' => 'x' } }
        assert_equal(
            nil,
            h.getLeaf( [] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'b' ] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'a' ] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'a', 'b', 'c' ] )
        )
        assert_equal(
            nil,
            h.getLeaf( [ 'a', 'c' ] )
        )
        assert_equal(
            'x',
            h.getLeaf( [ 'a', 'b' ] )
        )
    end
    
    def test_leaves
        h = {}
        assert_equal(
            Set.new( [] ),
            h.leaves
        )
        
        h = { 'a' => 'x' }
        assert_equal(
            Set.new( [ 'x' ] ),
            h.leaves
        )
        
        h = { 'a' => 'x', 'b' => 'y' }
        assert_equal(
            Set.new( [ 'x', 'y' ] ),
            h.leaves
        )
        
        h = { 'a' => { 'b' => 'x' }, 'c' => 'y' }
        assert_equal(
            Set.new( [ 'x', 'y' ] ),
            h.leaves
        )
        
        h = { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } }
        assert_equal(
            Set.new( [ 'x', 'y' ] ),
            h.leaves
        )
        
        h = { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y', 'e' => 'z' }, 'f' => 'w' }
        assert_equal(
            Set.new( [ 'x', 'y', 'z', 'w' ] ),
            h.leaves
        )
    end
end