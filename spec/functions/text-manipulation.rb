require 'spec/preparation'

describe 'Diakonos' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
  end

  it 'collapses whitespace' do
    @b.to_a[ 2 ].should.equal '# This is only a sample file used in the tests.'
    @b.cursor_to 2,9
    5.times { @d.type_character ' ' }
    cursor_should_be_at 2,14
    @b.to_a[ 2 ].should.equal '# This is      only a sample file used in the tests.'
    @d.collapse_whitespace
    cursor_should_be_at 2,9
    @b.to_a[ 2 ].should.equal '# This is only a sample file used in the tests.'
  end

  it 'columnizes source code' do
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

  it 'can comment out and uncomment lines' do
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

end
