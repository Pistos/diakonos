require 'spec/preparation'

describe 'Diakonos' do

  before do
    @d = $diakonos
    @b = @d.openFile( SAMPLE_FILE )
  end

  it 'allows basic cursor movements' do
    original_lines = @b.to_a
    @b.current_row.should.equal 0
    @b.current_column.should.equal 0
  end

end