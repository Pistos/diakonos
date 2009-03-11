require 'spec/preparation'

describe 'A Hash' do
  it 'can delete a key path' do
    g = {}
    h = g.deep_clone
    h.deleteKeyPath( [] ).should.equal( {} )
    h = g.deep_clone
    h.deleteKeyPath( [ 'test' ] ).should.equal( {} )
    h = g.deep_clone
    h.deleteKeyPath( [ 'test', 'test2' ] ).should.equal( {} )

    g = { 'a' => 'x' }
    h = g.deep_clone
    h.deleteKeyPath( [] ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'test' ] ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'test', 'test2' ] ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a' ] ).should.equal( {} )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b' ] ).should.equal( { 'a' => 'x' } )

    g = {
      'a' => {
        'b' => 'x'
      }
    }
    h = g.deep_clone
    h.deleteKeyPath( [] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'z' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'z', 'zz' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b', 'c' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a' ] ).should.equal( {} )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b' ] ).should.equal( {} )

    g = {
      'a' => {
        'b' => 'x',
        'c' => 'y'
      }
    }
    h = g.deep_clone
    h.deleteKeyPath( [] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'z' ] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'z', 'zz' ] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b', 'c' ] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a' ] ).should.equal( {} )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b' ] ).should.equal( { 'a' => { 'c' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'c' ] ).should.equal( { 'a' => { 'b' => 'x' } } )

    g = {
      'a' => {
        'b' => 'x'
      },
      'c' => {
        'd' => 'y'
      }
    }
    h = g.deep_clone
    h.deleteKeyPath( [] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'z' ] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'z', 'zz' ] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b', 'c' ] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a' ] ).should.equal( { 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'c' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'a', 'b' ] ).should.equal( { 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.deleteKeyPath( [ 'c', 'd' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
  end

  it 'can set a key path' do
    g = {}
    h = g.deep_clone
    h.setKeyPath( [], 'x' ).should.equal( {} )
    h = g.deep_clone
    h.setKeyPath( [ 'a' ], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.setKeyPath( [ 'a', 'b' ], 'x' ).should.equal( { 'a' => { 'b' => 'x' } } )

    g = { 'a' => 'x' }
    h = g.deep_clone
    h.setKeyPath( [], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.setKeyPath( [ 'a' ], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.setKeyPath( [ 'a', 'b' ], 'x' ).should.equal( { 'a' => { 'b' => 'x' } } )

    g = { 'c' => 'y' }
    h = g.deep_clone
    h.setKeyPath( [], 'x' ).should.equal( { 'c' => 'y' } )
    h = g.deep_clone
    h.setKeyPath( [ 'a' ], 'x' ).should.equal( { 'c' => 'y', 'a' => 'x' } )
    h = g.deep_clone
    h.setKeyPath( [ 'a', 'b' ], 'x' ).should.equal( { 'c' => 'y', 'a' => { 'b' => 'x' } } )

    g = { 'a' => { 'b' => 'x' } }
    h = g.deep_clone
    h.setKeyPath( [], 'x' ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.setKeyPath( [ 'a' ], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.setKeyPath( [ 'c' ], 'y' ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => 'y' } )
    h = g.deep_clone
    h.setKeyPath( [ 'c', 'd' ], 'y' ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
  end

  it 'can get a node' do
    h = {}
    h.getNode( [] ).should.be.nil
    h.getNode( [ 'a' ] ).should.be.nil
    h.getNode( [ 'a', 'b' ] ).should.be.nil

    h = { 'a' => 'x' }
    h.getNode( [] ).should.be.nil
    h.getNode( [ 'b' ] ).should.be.nil
    h.getNode( [ 'a' ] ).should.equal( 'x' )

    h = { 'a' => { 'b' => 'x' } }
    h.getNode( [] ).should.be.nil
    h.getNode( [ 'b' ] ).should.be.nil
    h.getNode( [ 'a' ] ).should.equal( { 'b' => 'x' } )
    h.getNode( [ 'a', 'b', 'c' ] ).should.be.nil
    h.getNode( [ 'a', 'c' ] ).should.be.nil
    h.getNode( [ 'a', 'b' ] ).should.equal( 'x' )
  end

  it 'can get a leaf' do
    h = {}
    h.getLeaf( [] ).should.be.nil
    h.getLeaf( [ 'a' ] ).should.be.nil
    h.getLeaf( [ 'a', 'b' ] ).should.be.nil

    h = { 'a' => 'x' }
    h.getLeaf( [] ).should.be.nil
    h.getLeaf( [ 'b' ] ).should.be.nil
    h.getLeaf( [ 'a' ] ).should.equal( 'x' )

    h = { 'a' => { 'b' => 'x' } }
    h.getLeaf( [] ).should.be.nil
    h.getLeaf( [ 'b' ] ).should.be.nil
    h.getLeaf( [ 'a' ] ).should.be.nil
    h.getLeaf( [ 'a', 'b', 'c' ] ).should.be.nil
    h.getLeaf( [ 'a', 'c' ] ).should.be.nil
    h.getLeaf( [ 'a', 'b' ] ).should.equal( 'x' )
  end

  it 'can list leaves' do
    h = {}
    h.leaves.should.equal( Set.new( [] ) )

    h = { 'a' => 'x' }
    h.leaves.should.equal( Set.new( [ 'x' ] ) )

    h = { 'a' => 'x', 'b' => 'y' }
    h.leaves.should.equal( Set.new( [ 'x', 'y' ] ) )

    h = { 'a' => { 'b' => 'x' }, 'c' => 'y' }
    h.leaves.should.equal( Set.new( [ 'x', 'y' ] ) )

    h = { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } }
    h.leaves.should.equal( Set.new( [ 'x', 'y' ] ) )

    h = { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y', 'e' => 'z' }, 'f' => 'w' }
    h.leaves.should.equal( Set.new( [ 'x', 'y', 'z', 'w' ] ) )
  end
end