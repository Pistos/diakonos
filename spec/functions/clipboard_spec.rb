require 'spec_helper'

RSpec.describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'copy selected text' do
    @d.anchor_selection
    @d.cursor_down
    @d.cursor_down
    @d.cursor_down
    @d.copy_selection
    expect(@d.clipboard.clip).to eq [
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
    expect(@d.clipboard.clip).to eq [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
    ]

    lines = @b.to_a
    expect(lines.size).to eq 24
    expect(lines[ 0..2 ]).to eq [
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
    expect(lines.size).to eq 30
    expect(lines[ 0..8 ]).to eq [
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
    @d.functions_last << 'delete_and_store_line'
    expect(@d.clipboard.clip).to eq( [
      '#!/usr/bin/env ruby',
      '',
    ] )
    @d.delete_and_store_line
    @d.functions_last << 'delete_and_store_line'
    expect(@d.clipboard.clip).to eq( [
      '#!/usr/bin/env ruby',
      '',
      '',
    ] )
    @d.delete_and_store_line
    @d.functions_last << 'delete_and_store_line'
    expect(@d.clipboard.clip).to eq( [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
    ] )
    expect(@b.to_a).not_to eq original_lines

    @d.paste
    expect(@b.to_a).to eq original_lines
  end

end
