require 'spec/preparation'

describe 'Diakonos' do

  before do
    @d = $diakonos
    @b = @d.openFile( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  it 'lets you select text' do
    @d.anchor_selection
    @d.cursor_down
    @d.cursor_down
    @d.cursor_down
    cursor_should_be_at 3,0

    selection = @b.selection_mark
    selection.start_row.should.equal 0
    selection.start_col.should.equal 0
    selection.end_row.should.equal 3
    selection.end_col.should.equal 0
  end

  it 'lets you stop selecting text' do
    @b.selection_mark.should.be.nil
    @d.anchor_selection
    @d.cursor_down
    @d.cursor_down
    @b.selection_mark.should.not.be.nil
    @d.remove_selection
    @b.selection_mark.should.be.nil
  end

end