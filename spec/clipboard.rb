require_relative 'preparation'

describe 'A Diakonos::Clipboard' do
  it 'can accept new clips via #add_clip' do
    c = Diakonos::Clipboard.new( 3 )
    c.add_clip( nil ).should.be.false
    c.add_clip( [ 'foo' ] ).should.be.true
    c.add_clip( [ 'bar' ] ).should.be.true
    c.add_clip( [ 'baz' ] ).should.be.true
    c[ 2 ].should.equal [ 'foo' ]
    c[ 3 ].should.be.nil
    c.add_clip( [ 'fiz' ] ).should.be.true
    c[ 2 ].should.equal [ 'bar' ]
    c[ 3 ].should.be.nil
  end

  it 'provides access to clips via #[]' do
    c = Diakonos::Clipboard.new( 3 )
    c[ -1 ].should.be.nil
    c[ 0 ].should.be.nil
    c[ 1 ].should.be.nil
    c.add_clip( nil ).should.be.false
    x = [ 'foo' ]
    c.add_clip( x ).should.be.true
    c[ -1 ].should.equal x
    c[ 0 ].should.equal x
    c[ 1 ].should.be.nil
  end

  it 'can be iterated over via #each' do
    c = Diakonos::Clipboard.new( 10 )
    9.downto( 0 ) do |i|
      c.add_clip( [ i.to_s ] )
    end
    i = 0
    c.each do |clip|
      clip.should.equal [ i.to_s ]
      i += 1
    end
  end

  it 'provides #append_to_clip to append to clips' do
    c = Diakonos::Clipboard.new( 10 )
    c.append_to_clip( nil ).should.be.false
    x = [ 'foo' ]
    c.append_to_clip( x ).should.be.true
    c.clip.should.equal [ 'foo' ]

    c.append_to_clip( [ 'bar', 'baz' ] ).should.be.true
    c.clip.should.equal [ 'foo', 'bar', 'baz' ]

    y = [ 'line with newline', '' ]
    c.add_clip( y ).should.be.true
    c.clip.should.equal y
    c.append_to_clip( [ 'another line' ] ).should.be.true
    c.clip.should.equal [ 'line with newline', 'another line' ]

    c.add_clip( [ 'line1', '' ] ).should.be.true
    c.clip.should.equal [ 'line1', '' ]
    c.append_to_clip( [ '', '' ] ).should.be.true
    c.clip.should.equal [ 'line1', '', '' ]
    c.append_to_clip( [ 'line2', '' ] ).should.be.true
    c.clip.should.equal [ 'line1', '', 'line2', '' ]
  end
end