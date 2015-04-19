require 'spec_helper'

RSpec.describe 'A KeyMap' do
  it 'can delete a key path' do
    g = {}.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.delete_key_path( [] )).to eq( {} )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'test' ] )).to eq( {} )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'test', 'test2' ] )).to eq( {} )

    g = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.delete_key_path( [] )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'test' ] )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'test', 'test2' ] )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a' ] )).to eq( {} )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b' ] )).to eq( { 'a' => 'x' } )

    g = {
      'a' => {
        'b' => 'x'
      }
    }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.delete_key_path( [] )).to eq( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'z' ] )).to eq( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'z', 'zz' ] )).to eq( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b', 'c' ] )).to eq( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a' ] )).to eq( {} )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b' ] )).to eq( {} )

    g = {
      'a' => {
        'b' => 'x',
        'c' => 'y'
      }
    }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.delete_key_path( [] )).to eq( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'z' ] )).to eq( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'z', 'zz' ] )).to eq( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b', 'c' ] )).to eq( { 'a' => { 'b' => 'x', 'c' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a' ] )).to eq( {} )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b' ] )).to eq( { 'a' => { 'c' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'c' ] )).to eq( { 'a' => { 'b' => 'x' } } )

    g = {
      'a' => {
        'b' => 'x'
      },
      'c' => {
        'd' => 'y'
      }
    }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.delete_key_path( [] )).to eq( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'z' ] )).to eq( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'z', 'zz' ] )).to eq( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b', 'c' ] )).to eq( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a' ] )).to eq( { 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'c' ] )).to eq( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'a', 'b' ] )).to eq( { 'c' => { 'd' => 'y' } } )
    h = g.deep_clone
    expect(h.delete_key_path( [ 'c', 'd' ] )).to eq( { 'a' => { 'b' => 'x' } } )
  end

  it 'can set a key path' do
    g = {}.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.set_key_path( [], 'x' )).to eq( {} )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a' ], 'x' )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a', 'b' ], 'x' )).to eq( { 'a' => { 'b' => 'x' } } )

    g = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.set_key_path( [], 'x' )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a' ], 'x' )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a', 'b' ], 'x' )).to eq( { 'a' => { 'b' => 'x' } } )

    g = { 'c' => 'y' }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.set_key_path( [], 'x' )).to eq( { 'c' => 'y' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a' ], 'x' )).to eq( { 'c' => 'y', 'a' => 'x' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a', 'b' ], 'x' )).to eq( { 'c' => 'y', 'a' => { 'b' => 'x' } } )

    g = { 'a' => { 'b' => 'x' } }.extend( Diakonos::KeyMap )
    h = g.deep_clone
    expect(h.set_key_path( [], 'x' )).to eq( { 'a' => { 'b' => 'x' } } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'a' ], 'x' )).to eq( { 'a' => 'x' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'c' ], 'y' )).to eq( { 'a' => { 'b' => 'x' }, 'c' => 'y' } )
    h = g.deep_clone
    expect(h.set_key_path( [ 'c', 'd' ], 'y' )).to eq( { 'a' => { 'b' => 'x' }, 'c' => { 'd' => 'y' } } )
  end

  it 'can get a node' do
    h = {}.extend( Diakonos::KeyMap )
    expect(h.get_node( [] )).to be_nil
    expect(h.get_node( [ 'a' ] )).to be_nil
    expect(h.get_node( [ 'a', 'b' ] )).to be_nil

    h = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    expect(h.get_node( [] )).to be_nil
    expect(h.get_node( [ 'b' ] )).to be_nil
    expect(h.get_node( [ 'a' ] )).to eq( 'x' )

    h = { 'a' => { 'b' => 'x' } }.extend( Diakonos::KeyMap )
    expect(h.get_node( [] )).to be_nil
    expect(h.get_node( [ 'b' ] )).to be_nil
    expect(h.get_node( [ 'a' ] )).to eq( { 'b' => 'x' } )
    expect(h.get_node( [ 'a', 'b', 'c' ] )).to be_nil
    expect(h.get_node( [ 'a', 'c' ] )).to be_nil
    expect(h.get_node( [ 'a', 'b' ] )).to eq( 'x' )
  end

  it 'can get a leaf' do
    h = {}.extend( Diakonos::KeyMap )
    expect(h.get_leaf( [] )).to be_nil
    expect(h.get_leaf( [ 'a' ] )).to be_nil
    expect(h.get_leaf( [ 'a', 'b' ] )).to be_nil

    h = { 'a' => 'x' }.extend( Diakonos::KeyMap )
    expect(h.get_leaf( [] )).to be_nil
    expect(h.get_leaf( [ 'b' ] )).to be_nil
    expect(h.get_leaf( [ 'a' ] )).to eq( 'x' )

    h = { 'a' => { 'b' => 'x' } }.extend( Diakonos::KeyMap )
    expect(h.get_leaf( [] )).to be_nil
    expect(h.get_leaf( [ 'b' ] )).to be_nil
    expect(h.get_leaf( [ 'a' ] )).to be_nil
    expect(h.get_leaf( [ 'a', 'b', 'c' ] )).to be_nil
    expect(h.get_leaf( [ 'a', 'c' ] )).to be_nil
    expect(h.get_leaf( [ 'a', 'b' ] )).to eq( 'x' )
  end

end
