require 'spec/preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
  end

  after do
    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
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
    @d.cursor_eol
    cursor_should_be_at 0,19
  end

  it 'move the cursor to the beginning of a line' do
    @b.cursor_to 2,2
    @d.cursor_bol
    cursor_should_be_at 2,0
  end

  it 'move the cursor to the end of a file' do
    @d.cursor_eof
    cursor_should_be_at 26,40
  end

  it 'move the cursor to the beginning of a file' do
    @b.cursor_to 2,2
    @d.cursor_bof
    cursor_should_be_at 0,0
  end

  it 'move the cursor to the next occurrence of a character' do
    cursor_should_be_at 0,0
    @d.go_to_char 'c'
    cursor_should_be_at 4,0
    @d.go_to_char 'a'
    cursor_should_be_at 4,2
    @d.go_to_char 'a'
    cursor_should_be_at 4,7
    @d.go_to_char ':'
    cursor_should_be_at 5,14
    @d.go_to_char '='
    cursor_should_be_at 8,7
    @d.go_to_char '`'
    cursor_should_be_at 8,7

    @b.cursor_to 18,0
    @b.go_to_char 's'
    cursor_should_be_at 19,0
  end

  it 'move the cursor to the closest previous occurrence of a character' do
    @d.cursor_eof
    cursor_should_be_at 26,40
    @d.go_to_char_previous '.'
    cursor_should_be_at 19,1
    @d.go_to_char_previous 'e'
    cursor_should_be_at 18,12
    @d.go_to_char_previous 's'
    cursor_should_be_at 18,0
    @d.go_to_char_previous 't'
    cursor_should_be_at 14,12
    @d.go_to_char_previous 't'
    cursor_should_be_at 13,12
    @d.go_to_char_previous '%'
    cursor_should_be_at 13,12

    @b.cursor_to 19,0
    @b.go_to_char_previous 's'
    cursor_should_be_at 18,0
  end

end