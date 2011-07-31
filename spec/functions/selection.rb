require_relative '../preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer @b, Diakonos::CHOICE_NO_TO_ALL
  end

  it 'select text' do
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

  it 'stop selecting text' do
    @b.selection_mark.should.be.nil
    @d.anchor_selection
    @d.cursor_down
    @d.cursor_down
    @b.selection_mark.should.not.be.nil
    @d.remove_selection
    @b.selection_mark.should.be.nil
  end

  it 'select the whole file at once' do
    @b.selection_mark.should.be.nil
    @d.select_all
    s = @b.selection_mark
    s.start_row.should.equal 0
    s.start_col.should.equal 0
    s.end_row.should.equal 26
    s.end_col.should.equal 40
  end

  it 'delete the selection' do
    @d.anchor_selection
    3.times { @d.cursor_down }
    @d.delete
    @b.to_a[ 0..2 ].should.equal [
      '',
      'class Sample',
      '  attr_reader :x, :y',
    ]
    cursor_should_be_at 0,0
  end

  it 'select the word at the cursor position' do
    @b.cursor_to 2,4
    @d.select_word
    selection_should_be 2,2, 2,6
    cursor_should_be_at 2,6

    @b.cursor_to 2,2
    @d.select_word
    selection_should_be 2,2, 2,6
    cursor_should_be_at 2,6

    @b.cursor_to 2,5
    @d.select_word
    selection_should_be 2,2, 2,6
    cursor_should_be_at 2,6

    @b.cursor_to 2,1
    @d.select_word
    selection_should_be 2,2, 2,6
    cursor_should_be_at 2,6
    @d.cursor_right
    selection_should_be 2,2, 2,7
    cursor_should_be_at 2,7

    @d.remove_selection
    @b.cursor_to 26,40
    @d.select_word
    s = @b.selection_mark
    s.should.be.nil
    cursor_should_be_at 26,40
  end

  it 'extend a selection wordwise' do
    @b.cursor_to 2,4
    @d.select_word
    selection_should_be 2,2, 2,6

    @d.select_word_another
    selection_should_be 2,2, 2,9
    cursor_should_be_at 2,9
    @d.select_word_another
    selection_should_be 2,2, 2,14
    cursor_should_be_at 2,14
    @d.select_word_another
    selection_should_be 2,2, 2,16
    cursor_should_be_at 2,16
    @d.select_word_another
    selection_should_be 2,2, 2,23
    cursor_should_be_at 2,23
    @d.cursor_right
    selection_should_be 2,2, 2,24
    cursor_should_be_at 2,24

    @d.remove_selection
    @b.cursor_to 26,34
    @d.select_word
    selection_should_be 26,34, 26,36

    @d.select_word_another
    selection_should_be 26,34, 26,40
    @d.select_word_another
    selection_should_be 26,34, 26,40
  end

end
