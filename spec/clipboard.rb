require 'spec/preparation'

describe 'A Diakonos::Clipboard' do
  it 'can accept new clips via #addClip' do
    c = Diakonos::Clipboard.new( 3 )
    c.addClip( nil ).should.be.false
    c.addClip( [ 'foo' ] ).should.be.true
    c.addClip( [ 'bar' ] ).should.be.true
    c.addClip( [ 'baz' ] ).should.be.true
    c[ 2 ].should.equal [ 'foo' ]
    c[ 3 ].should.be.nil
    c.addClip( [ 'fiz' ] ).should.be.true
    c[ 2 ].should.equal [ 'bar' ]
    c[ 3 ].should.be.nil
  end

  it 'provides access to clips via #[]' do
    c = Diakonos::Clipboard.new( 3 )
    c[ -1 ].should.be.nil
    c[ 0 ].should.be.nil
    c[ 1 ].should.be.nil
    c.addClip( nil ).should.be.false
    x = [ 'foo' ]
    c.addClip( x ).should.be.true
    c[ -1 ].should.equal x
    c[ 0 ].should.equal x
    c[ 1 ].should.be.nil
  end

  it 'can be iterated over via #each' do
    c = Diakonos::Clipboard.new( 10 )
    9.downto( 0 ) do |i|
      c.addClip( [ i.to_s ] )
    end
    i = 0
    c.each do |clip|
      clip.should.equal [ i.to_s ]
      i += 1
    end
  end

  it 'provides #appendToClip to append to clips' do
    c = Diakonos::Clipboard.new( 10 )
    c.appendToClip( nil ).should.be.false
    x = [ 'foo' ]
    c.appendToClip( x ).should.be.true
    c.clip.should.equal [ 'foo' ]

    c.appendToClip( [ 'bar', 'baz' ] ).should.be.true
    c.clip.should.equal [ 'foo', 'bar', 'baz' ]

    y = [ 'line with newline', '' ]
    c.addClip( y ).should.be.true
    c.clip.should.equal y
    c.appendToClip( [ 'another line' ] ).should.be.true
    c.clip.should.equal [ 'line with newline', 'another line' ]

    c.addClip( [ 'line1', '' ] ).should.be.true
    c.clip.should.equal [ 'line1', '' ]
    c.appendToClip( [ '', '' ] ).should.be.true
    c.clip.should.equal [ 'line1', '', '' ]
    c.appendToClip( [ 'line2', '' ] ).should.be.true
    c.clip.should.equal [ 'line1', '', 'line2', '' ]
  end
end