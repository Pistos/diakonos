require 'spec/preparation'

def cursor_should_be_at( row, col )
  @b.current_row.should.equal row
  @b.current_column.should.equal col
end

describe 'Diakonos' do

  before do
    @d = $diakonos
    @b = @d.openFile( SAMPLE_FILE )
  end

  it 'allows basic cursor movements' do
    original_lines = @b.to_a
    cursor_should_be_at 0,0

    @d.cursor_down
    cursor_should_be_at 1,0
    @d.cursor_up
    cursor_should_be_at 0,0
    @d.cursor_right
    cursor_should_be_at 0,1
    @d.cursor_left
    cursor_should_be_at 0,0

    @d.cursor_eol
    cursor_should_be_at 0,19
    @d.cursor_bol
    cursor_should_be_at 0,0

    @d.cursor_eof
    cursor_should_be_at 20,0
    @d.cursor_bof
    cursor_should_be_at 0,0
  end

end