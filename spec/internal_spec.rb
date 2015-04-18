require_relative 'preparation'

describe '::Diakonos can' do

  it 'parse a filename and line number from a String' do
    ::Diakonos.parse_filename_and_line_number( 'abc.rb' ).should.equal [ 'abc.rb', nil ]
    ::Diakonos.parse_filename_and_line_number( '/absolute/path/abc.rb' ).should.equal [ '/absolute/path/abc.rb', nil ]
    ::Diakonos.parse_filename_and_line_number( 'abc.rb:1' ).should.equal [ 'abc.rb', 0 ]
    ::Diakonos.parse_filename_and_line_number( 'abc.rb:5' ).should.equal [ 'abc.rb', 4 ]
    ::Diakonos.parse_filename_and_line_number( 'abc.rb:10' ).should.equal [ 'abc.rb', 9 ]
    ::Diakonos.parse_filename_and_line_number( '/absolute/path/abc.rb:15' ).should.equal [ '/absolute/path/abc.rb', 14 ]
    ::Diakonos.parse_filename_and_line_number( 'relative/path/abc.rb:15' ).should.equal [ 'relative/path/abc.rb', 14 ]
  end

end
