require 'spec_helper'

RSpec.describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'move the cursor in the four basic directions' do
    cursor_should_be_at 0,0

    @d.cursor_down
    cursor_should_be_at 1,0
    @d.cursor_up
    cursor_should_be_at 0,0
    @d.cursor_right
    cursor_should_be_at 0,1
    @d.cursor_left
    cursor_should_be_at 0,0
  end

  it 'move the cursor to the end of a line' do
    cursor_should_be_at 0, 0
    @d.cursor_eol
    cursor_should_be_at 0, 19
  end

  context 'with soft wrap enabled and a long line above the cursor' do
    let(:long_line) { 'x' * (Curses.cols + 5) }
    let(:target_line) { 'hello' }

    before do
      @b.instance_variable_set(:@lines, [long_line, target_line])
      @b.instance_variable_get(:@settings)['view.wrap.soft'] = true
    end

    after do
      @b.instance_variable_get(:@settings)['view.wrap.soft'] = false
    end

    context 'when the cursor is on the line after the wrapped line' do
      before do
        @b.cursor_to(1, 0)
      end

      it 'move the cursor to the end of the actual current line' do
        cursor_should_be_at 1, 0
        @d.cursor_eol
        cursor_should_be_at 1, target_line.length
      end
    end

    context 'when the cursor is on a continuation visual segment of the wrapped line' do
      before do
        @b.cursor_to(0, Curses.cols + 2)
      end

      it 'move the cursor to the end of that same buffer line' do
        cursor_should_be_at 0, Curses.cols + 2
        @d.cursor_eol
        cursor_should_be_at 0, long_line.length
      end
    end
  end

  it 'move the cursor to the beginning of a line' do
    @b.cursor_to 2,2
    @d.cursor_bol
    cursor_should_be_at 2,0
  end

  it 'move the cursor to the end of a file' do
    @d.cursor_eof
    cursor_should_be_at 32,40
  end

  it 'move the cursor to the beginning of a file' do
    @b.cursor_to 2,2
    @d.cursor_bof
    cursor_should_be_at 0,0
  end

  it 'move the cursor to the next occurrence of a character' do
    cursor_should_be_at 0,0

    @d.go_to_char :on, '.'
    cursor_should_be_at 2,46
    @d.go_to_char :on, 'c'
    cursor_should_be_at 4,0
    @d.go_to_char :on, 'a'
    cursor_should_be_at 4,2
    @d.go_to_char :on, 'a'
    cursor_should_be_at 4,7
    @d.go_to_char :on, ':'
    cursor_should_be_at 5,14
    @d.go_to_char :on, '='
    cursor_should_be_at 8,7
    @d.go_to_char :on, '`'
    cursor_should_be_at 8,7

    @b.cursor_to 0,0
    @d.go_to_char :after, '.'
    cursor_should_be_at 2,47
    @d.go_to_char :after, 'c'
    cursor_should_be_at 4,1
    @d.go_to_char :after, 'a'
    cursor_should_be_at 4,3
    @d.go_to_char :after, 'a'
    cursor_should_be_at 4,8
    @d.go_to_char :after, ':'
    cursor_should_be_at 5,15
    @d.go_to_char :after, '='
    cursor_should_be_at 8,8
    @d.go_to_char :after, '`'
    cursor_should_be_at 8,8

    @b.cursor_to 18,0
    @b.go_to_char 's'
    cursor_should_be_at 19,0
    @b.cursor_to 18,0
    @b.go_to_char 's', Diakonos::ON_CHAR
    cursor_should_be_at 19,0

    @b.cursor_to 18,0
    @b.go_to_char 's', Diakonos::AFTER_CHAR
    cursor_should_be_at 19,1
  end

  it 'move the cursor to the closest previous occurrence of a character' do
    @d.cursor_eof
    cursor_should_be_at 32,40
    @d.go_to_char_previous :on, '.'
    cursor_should_be_at 19,1
    @d.go_to_char_previous :on, 'e'
    cursor_should_be_at 18,12
    @d.go_to_char_previous :on, 's'
    cursor_should_be_at 18,0
    @d.go_to_char_previous :on, 't'
    cursor_should_be_at 14,12
    @d.go_to_char_previous :on, 't'
    r,c = 13,12
    cursor_should_be_at r,c
    @d.go_to_char_previous :on, '%'
    cursor_should_be_at r,c

    @d.cursor_eof
    cursor_should_be_at 32,40
    @d.go_to_char_previous :after, '.'
    cursor_should_be_at 19,2
    @d.go_to_char_previous :after, 'e'
    cursor_should_be_at 18,13
    @d.go_to_char_previous :after, 's'
    cursor_should_be_at 18,1
    @d.go_to_char_previous :after, 't'
    cursor_should_be_at 14,13
    @d.go_to_char_previous :after, 'i'
    cursor_should_be_at 14,7
    @d.go_to_char_previous :after, 'n'
    r,c = 13,8
    cursor_should_be_at r,c
    @d.go_to_char_previous :after, '%'
    cursor_should_be_at r,c

    @b.cursor_to 19,0
    @b.go_to_char_previous 's'
    cursor_should_be_at 18,0
    @b.cursor_to 19,0
    @b.go_to_char_previous 's', Diakonos::ON_CHAR
    cursor_should_be_at 18,0

    @b.cursor_to 19,0
    @b.go_to_char_previous 's', Diakonos::AFTER_CHAR
    cursor_should_be_at 18,1
  end

end
