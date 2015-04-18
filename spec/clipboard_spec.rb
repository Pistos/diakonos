require 'spec_helper'

RSpec.describe 'A Diakonos::Clipboard' do
  it 'can accept new clips via #add_clip' do
    c = Diakonos::Clipboard.new( 3 )
    expect(c.add_clip( nil )).to eq false
    expect(c.add_clip( [ 'foo' ] )).to eq true
    expect(c.add_clip( [ 'bar' ] )).to eq true
    expect(c.add_clip( [ 'baz' ] )).to eq true
    expect(c[ 2 ]).to eq [ 'foo' ]
    expect(c[ 3 ]).to eq nil
    expect(c.add_clip( [ 'fiz' ] )).to eq true
    expect(c[ 2 ]).to eq [ 'bar' ]
    expect(c[ 3 ]).to eq nil
  end

  it 'provides access to clips via #[]' do
    c = Diakonos::Clipboard.new( 3 )
    expect(c[ -1 ]).to eq nil
    expect(c[ 0 ]).to eq nil
    expect(c[ 1 ]).to eq nil
    expect(c.add_clip( nil )).to eq false
    x = [ 'foo' ]
    expect(c.add_clip( x )).to eq true
    expect(c[ -1 ]).to eq x
    expect(c[ 0 ]).to eq x
    expect(c[ 1 ]).to eq nil
  end

  it 'can be iterated over via #each' do
    c = Diakonos::Clipboard.new( 10 )
    9.downto( 0 ) do |i|
      c.add_clip( [ i.to_s ] )
    end
    i = 0
    c.each do |clip|
      expect(clip).to eq [ i.to_s ]
      i += 1
    end
  end

  it 'provides #append_to_clip to append to clips' do
    c = Diakonos::Clipboard.new( 10 )
    expect(c.append_to_clip( nil )).to eq false
    x = [ 'foo' ]
    expect(c.append_to_clip( x )).to eq true
    expect(c.clip).to eq [ 'foo' ]

    expect(c.append_to_clip( [ 'bar', 'baz' ] )).to eq true
    expect(c.clip).to eq [ 'foo', 'bar', 'baz' ]

    y = [ 'line with newline', '' ]
    expect(c.add_clip( y )).to eq true
    expect(c.clip).to eq y
    expect(c.append_to_clip( [ 'another line' ] )).to eq true
    expect(c.clip).to eq [ 'line with newline', 'another line' ]

    expect(c.add_clip( [ 'line1', '' ] )).to eq true
    expect(c.clip).to eq [ 'line1', '' ]
    expect(c.append_to_clip( [ '', '' ] )).to eq true
    expect(c.clip).to eq [ 'line1', '', '' ]
    expect(c.append_to_clip( [ 'line2', '' ] )).to eq true
    expect(c.clip).to eq [ 'line1', '', 'line2', '' ]
  end
end
