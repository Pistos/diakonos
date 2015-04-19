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

  it 'collapse whitespace' do
    expect(@b.to_a[ 2 ]).to eq '# This is only a sample file used in the tests.'
    @b.cursor_to 2,9
    5.times { @d.type_character ' ' }
    cursor_should_be_at 2,14
    expect(@b.to_a[ 2 ]).to eq '# This is      only a sample file used in the tests.'
    @d.collapse_whitespace
    cursor_should_be_at 2,9
    expect(@b.to_a[ 2 ]).to eq '# This is only a sample file used in the tests.'
  end

  it 'columnize source code' do
    @b.cursor_to 8,7
    3.times { @d.type_character ' ' }
    expect(@b.to_a[ 8..10 ]).to eq [
      '    @x    = 1',
      '    @y = 2',
      '  end',
    ]
    @b.cursor_to 8,0
    @d.anchor_selection
    2.times { @d.cursor_down }
    @d.columnize '='
    expect(@b.to_a[ 8..10 ]).to eq [
      '    @x    = 1',
      '    @y    = 2',
      '  end',
    ]
    cursor_should_be_at 10,0
  end

  it 'comment out and uncomment a single line' do
    @b.cursor_to 4,0
    expect(@b.selection_mark).to be_nil
    expect(@b.to_a[ 4 ]).to eq 'class Sample'
    @d.comment_out
    expect(@b.to_a[ 4 ]).to eq '# class Sample'
    @d.comment_out
    expect(@b.to_a[ 4 ]).to eq '# # class Sample'
    @d.uncomment
    expect(@b.to_a[ 4 ]).to eq '# class Sample'
    @d.uncomment
    expect(@b.to_a[ 4 ]).to eq 'class Sample'
    @d.uncomment
    expect(@b.to_a[ 4 ]).to eq 'class Sample'
  end

  it 'comment out and uncomment selected lines' do
    @b.cursor_to 7,0
    @d.anchor_selection
    4.times { @d.cursor_down }
    @d.comment_out
    expect(@b.to_a[ 7..11 ]).to eq [
      '  # def initialize',
      '    # @x = 1',
      '    # @y = 2',
      '  # end',
      '',
    ]
    expect(@b.selection_mark).not_to be_nil
    cursor_should_be_at 11,0

    @d.uncomment
    expect(@b.to_a[ 7..11 ]).to eq [
      '  def initialize',
      '    @x = 1',
      '    @y = 2',
      '  end',
      '',
    ]
    expect(@b.selection_mark).not_to be_nil
    cursor_should_be_at 11,0

    # Uncommenting lines that are not commented should do nothing
    @d.uncomment
    expect(@b.to_a[ 7..11 ]).to eq [
      '  def initialize',
      '    @x = 1',
      '    @y = 2',
      '  end',
      '',
    ]
    expect(@b.selection_mark).not_to be_nil
    cursor_should_be_at 11,0
  end

  it 'not comment out blank lines' do
    @b.cursor_to 3,0
    expect(@b.selection_mark).to be_nil
    expect(@b.to_a[ 3 ]).to eq ''
    @d.comment_out
    expect(@b.to_a[ 3 ]).to eq ''

    @b.cursor_to 6,0
    expect(@b.selection_mark).to be_nil
    expect(@b.to_a[ 6 ]).to eq ''
    @d.comment_out
    expect(@b.to_a[ 6 ]).to eq ''

    @b.cursor_to 5,0
    @d.anchor_selection
    3.times { @d.cursor_down }
    @d.comment_out
    expect(@b.to_a[ 5..7 ]).to eq [
      '  # attr_reader :x, :y',
      '',
      '  # def initialize',
    ]
    expect(@b.selection_mark).not_to be_nil
    cursor_should_be_at 8,0
  end

  it "doesn't duplicate comment closers" do
    b = @d.open_file(SAMPLE_FILE_JS)

    @d.comment_out
    expect(b.to_a[0]).to eq '/* function() { */'
    @d.comment_out
    expect(b.to_a[0]).to eq '/* /* function() { */'
    @d.uncomment
    expect(b.to_a[0]).to eq '/* function() { */'
    @d.uncomment
    expect(b.to_a[0]).to eq 'function() {'
  end

  it 'delete until a character' do
    @b.cursor_to 5,2
    expect(@b.to_a[ 5 ]).to eq '  attr_reader :x, :y'
    @d.delete_to ':'
    cursor_should_be_at 5,2
    expect(@b.to_a[ 5 ]).to eq '  :x, :y'
  end

  it 'delete from a character' do
    @b.cursor_to 12,11
    @d.delete_from ' '
    cursor_should_be_at 12,6
    expect(@b.to_a[12]).to eq '  def ction'

    @b.cursor_to 7,6
    @d.delete_from ' '
    cursor_should_be_at 7,6
    expect(@b.to_a[7]).to eq '  def initialize'

    @b.cursor_to 7,5
    @d.delete_from ' '
    cursor_should_be_at 7,2
    expect(@b.to_a[7]).to eq '   initialize'
  end

  it 'not delete from a non-existent character' do
    @b.cursor_to 7,6
    @d.delete_from '@'
    expect(@b).not_to be_modified
    expect(@b.to_a[7]).to eq '  def initialize'
  end

  it 'delete between matching characters' do
    @b.cursor_to 2,15
    expect(@b.to_a[ 2 ]).to eq '# This is only a sample file used in the tests.'
    @d.delete_to_and_from :not_inclusive, 'h'
    expect(@b.to_a[ 2 ]).to eq '# Thhe tests.'
    cursor_should_be_at 2,4

    @b.cursor_to 22,2
    @d.delete_to_and_from :not_inclusive, '{'
    lines = @b.to_a
    expect(lines.size).to eq 24
    expect(lines[ 21..22 ]).to eq [
      '{}',
      '',
    ]
  end

  it 'delete between matching characters, inclusive' do
    @b.cursor_to 2,15
    expect(@b.to_a[ 2 ]).to eq '# This is only a sample file used in the tests.'
    @d.delete_to_and_from :inclusive, 'h'
    expect(@b.to_a[ 2 ]).to eq '# Te tests.'
    cursor_should_be_at 2,3

    @b.cursor_to 22,2
    @d.delete_to_and_from :inclusive, '{'
    lines = @b.to_a
    expect(lines.size).to eq 24
    expect(lines[ 21..22 ]).to eq [
      '',
      '',
    ]
  end

  it 'automatically indent selected code' do
    @d.set_buffer_type 'text'
    @d.anchor_selection
    @d.cursor_eof
    expect(@b.selection_mark).not_to be_nil
    @d.parsed_indent
    expect(@b.to_a).to eq [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
      'class Sample',
      'attr_reader :x, :y',
      '',
      'def initialize',
      '@x = 1',
      '@y = 2',
      'end',
      '',
      'def inspection',
      'x.inspect',
      'y.inspect',
      'end',
      'end',
      '',
      's = Sample.new',
      's.inspection',
      '',
      '{',
      ':just => :a,',
      ':test => :hash,',
      '}',
      '',
      '# Comment at end, with no newline at EOF',
    ]

    @d.set_buffer_type 'ruby'
    expect(@b.selection_mark).not_to be_nil
    @d.parsed_indent
    expect(@b.to_a).to eq [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
      'class Sample',
      '  attr_reader :x, :y',
      '  ',
      '  def initialize',
      '    @x = 1',
      '    @y = 2',
      '  end',
      '  ',
      '  def inspection',
      '    x.inspect',
      '    y.inspect',
      '  end',
      'end',
      '',
      's = Sample.new',
      's.inspection',
      '',
      '{',
      '  :just => :a,',
      '  :test => :hash,',
      '}',
      '',
      '# Comment at end, with no newline at EOF',
    ]
  end

  it 'join lines' do
    @d.join_lines
    expect(@b.to_a[ 0..2 ]).to eq [
      '#!/usr/bin/env ruby ',
      '# This is only a sample file used in the tests.',
      '',
    ]
    @d.join_lines
    expect(@b.to_a[ 0..2 ]).to eq [
      '#!/usr/bin/env ruby  # This is only a sample file used in the tests.',
      '',
      'class Sample',
    ]
  end

  it 'surround selections with parentheses' do
    @b.set_selection 4, 6, 4, 12
    @d.surround_selection '('
    expect(@b[ 4 ]).to eq 'class ( Sample )'
    @d.undo

    @b.set_selection 4, 0, 4, 12
    @d.surround_selection '('
    expect(@b[ 4 ]).to eq '( class Sample )'
    @d.undo

    @b.set_selection 4, 0, 5, 20
    @d.surround_selection '('
    expect(@b[ 4..5 ]).to eq [
      '( class Sample',
      '  attr_reader :x, :y )'
    ]
    @d.undo

    @b.set_type 'html'

    @b.set_selection 7, 2, 7, 5
    @d.surround_selection '<!--'
    expect(@b[ 7 ]).to eq '  <!-- def --> initialize'
    @d.undo

    @b.set_selection 7, 2, 7, 5
    @d.surround_selection '<span>'
    expect(@b[ 7 ]).to eq '  <span>def</span> initialize'
    @d.undo
  end

  it 'word wrap paragraphs of text' do
    @b = @d.open_file( File.join(TEST_DIR, '/lorem-ipsum.txt') )
    expect(@b.length).to eq 2
    cursor_should_be_at 0,0

    @b.wrap_paragraph
    expect(@b.to_a).to eq [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Donec a diam lectus.',
      'Sed sit amet ipsum mauris.  Maecenas congue ligula ac quam viverra nec',
      'consectetur ante hendrerit.  Donec et mollis dolor.  Praesent et diam eget',
      'libero egestas mattis sit amet vitae augue.  Nam tincidunt congue enim, ut',
      'porta lorem lacinia consectetur.  Donec ut libero sed arcu vehicula ultricies a',
      'non tortor.  Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Aenean',
      'ut gravida lorem.  Ut turpis felis, pulvinar a semper sed, adipiscing id',
      'dolor.  Pellentesque auctor nisi id magna consequat sagittis.  Curabitur',
      'dapibus enim sit amet elit pharetra tincidunt feugiat nisl imperdiet.  Ut',
      'convallis libero in urna ultrices accumsan.  Donec sed odio eros.  Donec',
      'viverra mi quis quam pulvinar at malesuada arcu rhoncus.  Cum sociis natoque',
      'penatibus et magnis dis parturient montes, nascetur ridiculus mus.  In rutrum',
      'accumsan ultricies.  Mauris vitae nisi at sem facilisis semper ac in est.',
      '',
    ]
    cursor_should_be_at 13,0
  end

end
