require 'spec/preparation'

describe 'A KeyMap' do
  it 'can delete a key path' do
    g = {}.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.delete_key_path( [] ).should.equal( {} )
    h = g.deep_clone
    h.delete_key_path( [ 'test' ] ).should.equal( {} )
    h = g.deep_clone
    h.delete_key_path( [ 'test', 'test2' ] ).should.equal( {} )

    g = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.delete_key_path( [] ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.delete_key_path( [ 'test' ] ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.delete_key_path( [ 'test', 'test2' ] ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.delete_key_path( [ 'a' ] ).should.equal( {} )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b' ] ).should.equal( { 'a' => 'x' } )

    g = {
      'a' => {
        'b' => 'x'
      }
    }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.delete_key_path( [] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'z' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'z', 'zz' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b', 'c' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a' ] ).should.equal( {} )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b' ] ).should.equal( {} )

    g = {
      'a' => {
        'b' => 'x',
        'c' => 'y'
      }
    }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.delete_key_path( [] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'z' ] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'z', 'zz' ] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b', 'c' ] ).should.equal( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a' ] ).should.equal( {} )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b' ] ).should.equal( { 'a' => { 'c' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'c' ] ).should.equal( { 'a' => { 'b' => 'x' } } )

    g = {
      'a' => {
        'b' => 'x'
      },
      'c' => {
        'd' => 'y'
      }
    }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.delete_key_path( [] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'z' ] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'z', 'zz' ] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b', 'c' ] ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a' ] ).should.equal( { 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'c' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'a', 'b' ] ).should.equal( { 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    h.delete_key_path( [ 'c', 'd' ] ).should.equal( { 'a' => { 'b' => 'x' } } )
  end

  it 'can set a key path' do
    g = {}.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.set_key_path( [], 'x' ).should.equal( {} )
    h = g.deep_clone
    h.set_key_path( [ 'a' ], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.set_key_path( [ 'a', 'b' ], 'x' ).should.equal( { 'a' => { 'b' => 'x' } } )

    g = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.set_key_path( [], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.set_key_path( [ 'a' ], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.set_key_path( [ 'a', 'b' ], 'x' ).should.equal( { 'a' => { 'b' => 'x' } } )

    g = { 'c' => 'y' }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.set_key_path( [], 'x' ).should.equal( { 'c' => 'y' } )
    h = g.deep_clone
    h.set_key_path( [ 'a' ], 'x' ).should.equal( { 'c' => 'y', 'a' => 'x' } )
    h = g.deep_clone
    h.set_key_path( [ 'a', 'b' ], 'x' ).should.equal( { 'c' => 'y', 'a' => { 'b' => 'x' } } )

    g = { 'a' => { 'b' => 'x' } }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    h.set_key_path( [], 'x' ).should.equal( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    h.set_key_path( [ 'a' ], 'x' ).should.equal( { 'a' => 'x' } )
    h = g.deep_clone
    h.set_key_path( [ 'c' ], 'y' ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => 'y' } )
    h = g.deep_clone
    h.set_key_path( [ 'c', 'd' ], 'y' ).should.equal( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
  end

  it 'can get a node' do
    h = {}.extend( Diakonos::KeyMap )
    h.get_node( [] ).should.be.nil
    h.get_node( [ 'a' ] ).should.be.nil
    h.get_node( [ 'a', 'b' ] ).should.be.nil

    h = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    h.get_node( [] ).should.be.nil
    h.get_node( [ 'b' ] ).should.be.nil
    h.get_node( [ 'a' ] ).should.equal( 'x' )

    h = { 'a' => { 'b' => 'x' } }.extend( Diakonos::KeyMap )
    h.get_node( [] ).should.be.nil
    h.get_node( [ 'b' ] ).should.be.nil
    h.get_node( [ 'a' ] ).should.equal( { 'b' => 'x' } )
    h.get_node( [ 'a', 'b', 'c' ] ).should.be.nil
    h.get_node( [ 'a', 'c' ] ).should.be.nil
    h.get_node( [ 'a', 'b' ] ).should.equal( 'x' )
  end

  it 'can get a leaf' do
    h = {}.extend( Diakonos::KeyMap )
    h.get_leaf( [] ).should.be.nil
    h.get_leaf( [ 'a' ] ).should.be.nil
    h.get_leaf( [ 'a', 'b' ] ).should.be.nil

    h = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    h.get_leaf( [] ).should.be.nil
    h.get_leaf( [ 'b' ] ).should.be.nil
    h.get_leaf( [ 'a' ] ).should.equal( 'x' )

    h = { 'a' => { 'b' => 'x' } }.extend( Diakonos::KeyMap )
    h.get_leaf( [] ).should.be.nil
    h.get_leaf( [ 'b' ] ).should.be.nil
    h.get_leaf( [ 'a' ] ).should.be.nil
    h.get_leaf( [ 'a', 'b', 'c' ] ).should.be.nil
    h.get_leaf( [ 'a', 'c' ] ).should.be.nil
    h.get_leaf( [ 'a', 'b' ] ).should.equal( 'x' )
  end

end