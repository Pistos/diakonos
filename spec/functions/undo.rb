require_relative '../preparation'

def type( ch = $keystrokes.shift )
  @d.process_keystroke [], 'edit', ch
end

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'type one character and undo that typing' do
    @b.to_a[0].should.equal ''
    type 'a'
    @b.to_a[0].should.equal 'a'
    cursor_should_be_at 0,1

    @d.undo

    @b.to_a[0].should.equal ''
    cursor_should_be_at 0,0
  end

  it 'type several characters and undo all that typing with one undo' do
    @b.to_a[0].should.equal ''
    $keystrokes = [ 'a' ] * 8
    type
    @b.to_a[0].should.equal 'aaaaaaaa'
    cursor_should_be_at 0,8

    @d.undo

    @b.to_a[0].should.equal ''
    cursor_should_be_at 0,0
  end

  it 'type a carriage return and undo that carriage return' do
    lines = @b.to_a
    lines[0].should.equal ''
    lines.size.should.equal 1

    type 'a'
    sleep 1
    type Diakonos::ENTER
    lines = @b.to_a
    lines[0].should.equal 'a'
    lines[1].should.equal ''
    lines.size.should.equal 2
    cursor_should_be_at 1,0

    @d.undo
    lines = @b.to_a
    lines[0].should.equal 'a'
    lines.size.should.equal 1
    cursor_should_be_at 0,1
  end

end