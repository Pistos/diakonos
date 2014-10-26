require_relative '../preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'collapse whitespace' do
    @b.to_a[ 2 ].should.equal '# This is only a sample file used in the tests.'
    @b.cursor_to 2,9
    5.times { @d.type_character ' ' }
    cursor_should_be_at 2,14
    @b.to_a[ 2 ].should.equal '# This is      only a sample file used in the tests.'
    @d.collapse_whitespace
    cursor_should_be_at 2,9
    @b.to_a[ 2 ].should.equal '# This is only a sample file used in the tests.'
  end

  it 'columnize source code' do
    @b.cursor_to 8,7
    3.times { @d.type_character ' ' }
    @b.to_a[ 8..10 ].should.equal [
      '    @x    = 1',
      '    @y = 2',
      '  end',
    ]
    @b.cursor_to 8,0
    @d.anchor_selection
    2.times { @d.cursor_down }
    @d.columnize '='
    @b.to_a[ 8..10 ].should.equal [
      '    @x    = 1',
      '    @y    = 2',
      '  end',
    ]
    cursor_should_be_at 10,0
  end

  it 'comment out and uncomment a single line' do
    @b.cursor_to 4,0
    @b.selection_mark.should.be.nil
    @b.to_a[ 4 ].should.equal 'class Sample'
    @d.comment_out
    @b.to_a[ 4 ].should.equal '# class Sample'
    @d.comment_out
    @b.to_a[ 4 ].should.equal '# # class Sample'
    @d.uncomment
    @b.to_a[ 4 ].should.equal '# class Sample'
    @d.uncomment
    @b.to_a[ 4 ].should.equal 'class Sample'
    @d.uncomment
    @b.to_a[ 4 ].should.equal 'class Sample'
  end

  it 'comment out and uncomment selected lines' do
    @b.cursor_to 7,0
    @d.anchor_selection
    4.times { @d.cursor_down }
    @d.comment_out
    @b.to_a[ 7..11 ].should.equal [
      '  # def initialize',
      '    # @x = 1',
      '    # @y = 2',
      '  # end',
      '',
    ]
    @b.selection_mark.should.not.be.nil
    cursor_should_be_at 11,0

    @d.uncomment
    @b.to_a[ 7..11 ].should.equal [
      '  def initialize',
      '    @x = 1',
      '    @y = 2',
      '  end',
      '',
    ]
    @b.selection_mark.should.not.be.nil
    cursor_should_be_at 11,0

    # Uncommenting lines that are not commented should do nothing
    @d.uncomment
    @b.to_a[ 7..11 ].should.equal [
      '  def initialize',
      '    @x = 1',
      '    @y = 2',
      '  end',
      '',
    ]
    @b.selection_mark.should.not.be.nil
    cursor_should_be_at 11,0
  end

  it 'not comment out blank lines' do
    @b.cursor_to 3,0
    @b.selection_mark.should.be.nil
    @b.to_a[ 3 ].should.equal ''
    @d.comment_out
    @b.to_a[ 3 ].should.equal ''

    @b.cursor_to 6,0
    @b.selection_mark.should.be.nil
    @b.to_a[ 6 ].should.equal ''
    @d.comment_out
    @b.to_a[ 6 ].should.equal ''

    @b.cursor_to 5,0
    @d.anchor_selection
    3.times { @d.cursor_down }
    @d.comment_out
    @b.to_a[ 5..7 ].should.equal [
      '  # attr_reader :x, :y',
      '',
      '  # def initialize',
    ]
    @b.selection_mark.should.not.be.nil
    cursor_should_be_at 8,0
  end

  it "doesn't duplicate comment closers" do
    b = @d.open_file(SAMPLE_FILE_JS)

    @d.comment_out
    b.to_a[0].should.equal '/* function() { */'
    @d.comment_out
    b.to_a[0].should.equal '/* /* function() { */'
    @d.uncomment
    b.to_a[0].should.equal '/* function() { */'
    @d.uncomment
    b.to_a[0].should.equal 'function() {'
  end

  it 'delete until a character' do
    @b.cursor_to 5,2
    @b.to_a[ 5 ].should.equal '  attr_reader :x, :y'
    @d.delete_to ':'
    cursor_should_be_at 5,2
    @b.to_a[ 5 ].should.equal '  :x, :y'
  end

  it 'delete from a character' do
    @b.cursor_to 12,11
    @d.delete_from ' '
    cursor_should_be_at 12,6
    @b.to_a[12].should.equal '  def ction'

    @b.cursor_to 7,6
    @d.delete_from ' '
    cursor_should_be_at 7,6
    @b.to_a[7].should.equal '  def initialize'

    @b.cursor_to 7,5
    @d.delete_from ' '
    cursor_should_be_at 7,2
    @b.to_a[7].should.equal '   initialize'
  end

  it 'not delete from a non-existent character' do
    @b.cursor_to 7,6
    @d.delete_from '@'
    @b.should.not.be.modified
    @b.to_a[7].should.equal '  def initialize'
  end

  it 'delete between matching characters' do
    @b.cursor_to 2,15
    @b.to_a[ 2 ].should.equal '# This is only a sample file used in the tests.'
    @d.delete_to_and_from :not_inclusive, 'h'
    @b.to_a[ 2 ].should.equal '# Thhe tests.'
    cursor_should_be_at 2,4

    @b.cursor_to 22,2
    @d.delete_to_and_from :not_inclusive, '{'
    lines = @b.to_a
    lines.size.should.equal 24
    lines[ 21..22 ].should.equal [
      '{}',
      '',
    ]
  end

  it 'delete between matching characters, inclusive' do
    @b.cursor_to 2,15
    @b.to_a[ 2 ].should.equal '# This is only a sample file used in the tests.'
    @d.delete_to_and_from :inclusive, 'h'
    @b.to_a[ 2 ].should.equal '# Te tests.'
    cursor_should_be_at 2,3

    @b.cursor_to 22,2
    @d.delete_to_and_from :inclusive, '{'
    lines = @b.to_a
    lines.size.should.equal 24
    lines[ 21..22 ].should.equal [
      '',
      '',
    ]
  end

  it 'automatically indent selected code' do
    @d.set_buffer_type 'text'
    @d.anchor_selection
    @d.cursor_eof
    @b.selection_mark.should.not.be.nil
    @d.parsed_indent
    @b.to_a.should.equal [
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
    @b.selection_mark.should.not.be.nil
    @d.parsed_indent
    @b.to_a.should.equal [
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
    @b.to_a[ 0..2 ].should.equal [
      '#!/usr/bin/env ruby ',
      '# This is only a sample file used in the tests.',
      '',
    ]
    @d.join_lines
    @b.to_a[ 0..2 ].should.equal [
      '#!/usr/bin/env ruby  # This is only a sample file used in the tests.',
      '',
      'class Sample',
    ]
  end

  it 'surround selections with parentheses' do
    @b.set_selection 4, 6, 4, 12
    @d.surround_selection '('
    @b[ 4 ].should.equal 'class ( Sample )'
    @d.undo

    @b.set_selection 4, 0, 4, 12
    @d.surround_selection '('
    @b[ 4 ].should.equal '( class Sample )'
    @d.undo

    @b.set_selection 4, 0, 5, 20
    @d.surround_selection '('
    @b[ 4..5 ].should.equal [
      '( class Sample',
      '  attr_reader :x, :y )'
    ]
    @d.undo

    @b.set_type 'html'

    @b.set_selection 7, 2, 7, 5
    @d.surround_selection '<!--'
    @b[ 7 ].should.equal '  <!-- def --> initialize'
    @d.undo

    @b.set_selection 7, 2, 7, 5
    @d.surround_selection '<span>'
    @b[ 7 ].should.equal '  <span>def</span> initialize'
    @d.undo
  end

  it 'word wrap paragraphs of text' do
    @b = @d.open_file( File.join(TEST_DIR, '/lorem-ipsum.txt') )
    @b.length.should == 2
    cursor_should_be_at 0,0

    @b.wrap_paragraph
    @b.to_a.should == [
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
