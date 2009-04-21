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

end
