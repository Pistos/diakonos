require_relative 'preparation'

describe 'Diakonos can' do

  before do
    @d = $diakonos
  end

  after do
  end

  it 'parse a filename and line number from a String' do
    @d.parse_filename_and_line_number( 'abc.rb' ).should.equal [ 'abc.rb', nil ]
    @d.parse_filename_and_line_number( '/absolute/path/abc.rb' ).should.equal [ '/absolute/path/abc.rb', nil ]
    @d.parse_filename_and_line_number( 'abc.rb:1' ).should.equal [ 'abc.rb', 0 ]
    @d.parse_filename_and_line_number( 'abc.rb:5' ).should.equal [ 'abc.rb', 4 ]
    @d.parse_filename_and_line_number( 'abc.rb:10' ).should.equal [ 'abc.rb', 9 ]
    @d.parse_filename_and_line_number( '/absolute/path/abc.rb:15' ).should.equal [ '/absolute/path/abc.rb', 14 ]
    @d.parse_filename_and_line_number( 'relative/path/abc.rb:15' ).should.equal [ 'relative/path/abc.rb', 14 ]
  end

end
