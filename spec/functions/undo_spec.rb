require 'spec_helper'

def type( ch = $keystrokes.shift )
  @d.process_keystroke [], 'edit', ch
end

RSpec.describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'type one character and undo that typing' do
    expect(@b.to_a[0]).to eq ''
    type 'a'
    expect(@b.to_a[0]).to eq 'a'
    cursor_should_be_at 0,1

    @d.undo

    expect(@b.to_a[0]).to eq ''
    cursor_should_be_at 0,0
  end

  it 'type several characters and undo all that typing with one undo' do
    expect(@b.to_a[0]).to eq ''
    $keystrokes = [ 'a' ] * 8
    type
    expect(@b.to_a[0]).to eq 'aaaaaaaa'
    cursor_should_be_at 0,8

    @d.undo

    expect(@b.to_a[0]).to eq ''
    cursor_should_be_at 0,0
  end

  it 'type a carriage return and undo that carriage return' do
    lines = @b.to_a
    expect(lines[0]).to eq ''
    expect(lines.size).to eq 1

    type 'a'
    sleep 1
    type Diakonos::ENTER
    lines = @b.to_a
    expect(lines[0]).to eq 'a'
    expect(lines[1]).to eq ''
    expect(lines.size).to eq 2
    cursor_should_be_at 1,0

    @d.undo
    lines = @b.to_a
    expect(lines[0]).to eq 'a'
    expect(lines.size).to eq 1
    cursor_should_be_at 0,1
  end

end
