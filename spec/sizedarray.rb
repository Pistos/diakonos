require_relative 'preparation'

describe 'A SizedArray' do
  it 'can be instantiated with a size parameter' do
    a = SizedArray.new( 2 )
    a.capacity.should.equal 2
    a = SizedArray.new( 4 )
    a.capacity.should.equal 4
  end

  it 'can be appended to and provide overflow items' do
    a = SizedArray.new( 2 )

    a << 1
    a.should.equal [ 1 ]
    a << 2
    a.should.equal [ 1, 2 ]
    ( a << 3 ).should.equal 1
    a.should.equal [ 2, 3 ]
    ( a << 1 ).should.equal 2
    a.should.equal [ 3, 1 ]
  end

  it 'can be pushed to' do
    a = SizedArray.new( 2 )
    b = SizedArray.new( 2 )

    a.should.equal b

    a << 1
    b.push 1
    a.should.equal b
    a << 2
    b.push 2
    a.should.equal b
    a << 3
    b.push 3
    a.should.equal b
  end

  it 'can be unshifted to and provide overflow items' do
    a = SizedArray.new( 2 )

    a.unshift( 1 ).should.equal [ 1 ]
    a.unshift( 2 ).should.equal [ 2, 1 ]
    a.unshift( 3 ).should.equal 1
    a.should.equal [ 3, 2 ]
    a.unshift( 1 ).should.equal 2
    a.should.equal [ 1, 3 ]
  end

  it 'can be accept multiple items up to its size via #concat' do
    a = SizedArray.new( 4 )

    a.concat( [ 1, 2 ] ).should.equal [ 1, 2 ]
    a.concat( [ 3, 4 ] ).should.equal [ 1, 2, 3, 4 ]
    a.concat( [ 5, 6 ] ).should.equal [ 3, 4, 5, 6 ]
    a.concat( [ 7, 8, 9, 10 ] ).should.equal [ 7, 8, 9, 10 ]
    a.concat( [ 1, 2, 3, 4, 5, 6 ] ).should.equal [ 3, 4, 5, 6 ]
  end
end