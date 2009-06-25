require 'spec/preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
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
    lines.size.should.equal 24
    lines[ 0..2 ].should.equal [
      '',
      'class Sample',
      '  attr_reader :x, :y',
    ]
  end

  it 'paste from the clipboard' do
    @d.anchor_selection
    3.times { @d.cursor_down }
    @d.copy_selection
    @d.paste

    lines = @b.to_a
    lines.size.should.equal 30
    lines[ 0..8 ].should.equal [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
      'class Sample',
      '  attr_reader :x, :y',
    ]
  end

  it 'cut consecutive lines' do
    original_lines = @b.to_a

    @d.cursor_bof
    @d.delete_and_store_line
    @d.last_commands << 'delete_and_store_line'
    @d.clipboard.clip.should.equal( [
      '#!/usr/bin/env ruby',
      '',
    ] )
    @d.delete_and_store_line
    @d.last_commands << 'delete_and_store_line'
    @d.clipboard.clip.should.equal( [
      '#!/usr/bin/env ruby',
      '',
      '',
    ] )
    @d.delete_and_store_line
    @d.last_commands << 'delete_and_store_line'
    @d.clipboard.clip.should.equal( [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
    ] )
    @b.to_a.should.not.equal original_lines

    @d.paste
    @b.to_a.should.equal original_lines
  end

end
