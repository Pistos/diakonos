require_relative '../preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
  end

  it 'open a file at a specific line number' do
    b = @d.open_file( "#{SAMPLE_FILE_LONGER}:45" )
    b.current_row.should.equal 44
    b.current_column.should.equal 0
    b.top_line.should.equal 5
    b.left_column.should.equal 0
  end


end
