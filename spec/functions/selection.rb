require 'spec/preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.openFile( SAMPLE_FILE )
    cursor_should_be_at 0,0
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
    s.end_row.should.equal 20
    s.end_col.should.equal 0
  end

  it 'copy selected text' do
    @d.anchor_selection
    @d.cursor_down
    @d.cursor_down
    @d.cursor_down
    @d.copy_selection
    @d.clipboard.clip.should.equal [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
    ]
  end

  it 'cut selected text' do
    @d.anchor_selection
    @d.cursor_down
    @d.cursor_down
    @d.cursor_down
    @d.cut_selection
    @d.clipboard.clip.should.equal [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
    ]

    lines = @b.to_a
    lines.size.should.equal 18
    lines[ 0..2 ].should.equal [
      '',
      'class Sample',
      '  attr_reader :x, :y',
    ]
  end

end