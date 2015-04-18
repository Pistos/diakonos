require 'spec_helper'

describe 'A SizedArray' do
  it 'can be instantiated with a size parameter' do
    a = SizedArray.new( 2 )
    expect(a.capacity).to eq 2
    a = SizedArray.new( 4 )
    expect(a.capacity).to eq 4
  end

  it 'can be appended to and provide overflow items' do
    a = SizedArray.new( 2 )

    a << 1
    expect(a).to eq([ 1 ])
    a << 2
    expect(a).to eq([ 1, 2 ])
    expect(( a << 3 )).to eq 1
    expect(a).to eq([ 2, 3 ])
    expect(( a << 1 )).to eq 2
    expect(a).to eq([ 3, 1 ])
  end

  it 'can be pushed to' do
    a = SizedArray.new( 2 )
    b = SizedArray.new( 2 )

    expect(a).to eq b

    a << 1
    b.push 1
    expect(a).to eq b
    a << 2
    b.push 2
    expect(a).to eq b
    a << 3
    b.push 3
    expect(a).to eq b
  end

  it 'can be unshifted to and provide overflow items' do
    a = SizedArray.new( 2 )

    expect(a.unshift( 1 )).to eq([ 1 ])
    expect(a.unshift( 2 )).to eq([ 2, 1 ])
    expect(a.unshift( 3 )).to eq 1
    expect(a).to eq([ 3, 2 ])
    expect(a.unshift( 1 )).to eq 2
    expect(a).to eq([ 1, 3 ])
  end

  it 'can be accept multiple items up to its size via #concat' do
    a = SizedArray.new( 4 )

    expect(a.concat( [ 1, 2 ] )).to eq([ 1, 2 ])
    expect(a.concat( [ 3, 4 ] )).to eq([ 1, 2, 3, 4 ])
    expect(a.concat( [ 5, 6 ] )).to eq([ 3, 4, 5, 6 ])
    expect(a.concat( [ 7, 8, 9, 10 ] )).to eq([ 7, 8, 9, 10 ])
    expect(a.concat( [ 1, 2, 3, 4, 5, 6 ] )).to eq([ 3, 4, 5, 6 ])
  end
end
