require 'spec_helper'

RSpec.describe 'A Diakonos user' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'can grep the open buffers' do
    dir = File.dirname( File.expand_path( __FILE__ ) )

    @d.actually_grep( 'inspect', @d.buffer_current )
    lines = File.readlines( @d.list_filename )

    expect(lines[ 0 ])
    .to match %r(^sample-file\.rb:13:   def inspection {100,} \| #{dir}/test-files/sample-file\.rb:13\n$)

    expect(lines[ 1 ])
    .to match %r(^sample-file\.rb:14:     x\.inspect {100,} \| #{dir}/test-files/sample-file\.rb:14\n$)

    expect(lines[ 2 ])
    .to match %r(^sample-file\.rb:15:     y\.inspect {100,} \| #{dir}/test-files/sample-file\.rb:15\n$)

    expect(lines[ 3 ])
    .to match %r(^sample-file\.rb:20: s\.inspection {100,} \| #{dir}/test-files/sample-file\.rb:20\n$)

    expect(lines.size).to eq 4

    @d.close_list_buffer
  end

  it 'can find words' do
    @d.find 'is', word_only: true
    cursor_should_be_at 2,9
    selection_should_be 2,7, 2,9

    @d.find 'InSpEcT', word_only: true
    cursor_should_be_at 13,13
    selection_should_be 13,6, 13,13
  end

  it 'can find text searching down' do
    @d.find 'inspect'
    cursor_should_be_at 12, 13
    selection_should_be 12, 6, 12, 13

    @d.find 'inspect'
    cursor_should_be_at 13, 13
    selection_should_be 13, 6, 13, 13
  end

  it 'can find text searching up' do
    @b.cursor_to 26, 0
    @d.find 'inspect', direction: :up
    cursor_should_be_at 19, 9
    selection_should_be 19, 2, 19, 9
  end

  it 'finds case-insensitively by default' do
    @d.find 'Sample'
    cursor_should_be_at 2, 23
    selection_should_be 2, 17, 2, 23
  end

  it 'can find case-sensitively' do
    @d.find 'Sample', case_sensitive: true
    cursor_should_be_at 4, 12
    selection_should_be 4, 6, 4, 12
  end

  it 'wraps around when searching past end of file' do
    @b.cursor_to 20, 0
    @d.find 'inspect'
    cursor_should_be_at 12, 13

    expect(@b.instance_variable_get(:@wrapped)).to be true
  end

  it 'can find again after an initial find' do
    @d.find 'def'
    cursor_should_be_at 7, 5
    selection_should_be 7, 2, 7, 5

    @d.find_again
    cursor_should_be_at 12, 5
    selection_should_be 12, 2, 12, 5

    @d.find_again :up
    cursor_should_be_at 7, 5
    selection_should_be 7, 2, 7, 5
  end

  it 'can find exact literal strings' do
    @d.find_exact :down, 'x.inspect'
    cursor_should_be_at 13, 13
    selection_should_be 13, 4, 13, 13
  end

  it 'can seek to next match' do
    @d.seek 'def'
    cursor_should_be_at 7, 2

    @d.seek 'def'
    cursor_should_be_at 12, 2

    @d.seek 'def', :up
    cursor_should_be_at 7, 2
  end

  it 'tracks the number of matches found' do
    @d.find 'inspect'

    expect(@b.num_matches_found).to eq 4
  end

  it 'can go to a matching pair character' do
    @b.cursor_to 21, 0
    @d.go_to_pair_match
    cursor_should_be_at 24, 0

    @d.go_to_pair_match
    cursor_should_be_at 21, 0
  end

end

RSpec.describe 'A Diakonos Buffer' do

  before do
    @d = $diakonos
    @b = @d.open_file( BRACKET_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'can find next closest characters' do
    expect(@b.pos_of_next( /x/, 0, 0 )).to eq [ 1, 2, 'x' ]
    expect(@b.pos_of_next( /a/, 0, 0 )).to eq [ 2, 4, 'a' ]
    expect(@b.pos_of_next( /b/, 0, 0 )).to eq [ 3, 4, 'b' ]
    expect(@b.pos_of_next( /\}/, 0, 0 )).to eq [ 5, 15, '}' ]

    expect(@b.pos_of_next( /:/, 1, 2 )).to eq [ 1, 3, ':' ]
    expect(@b.pos_of_next( /a/, 2, 4 )).to eq [ 2, 4, 'a' ]
    expect(@b.pos_of_next( /\]/, 5, 9 )).to eq [ 5, 23, ']' ]

    expect(@b.pos_of_next( /q/, 0, 0 )).to be_nil
  end

  it 'can find previous closest characters' do
    expect(@b.pos_of_prev( /x/, 4, 9 )).to eq [ 1, 2, 'x' ]
    expect(@b.pos_of_prev( /a/, 4, 9 )).to eq [ 2, 4, 'a' ]
    expect(@b.pos_of_prev( /:/, 4, 7 )).to eq [ 4, 7, ':' ]

    expect(@b.pos_of_prev( /c/, 4, 7 )).to eq [ 4, 6, 'c' ]
    expect(@b.pos_of_prev( /\{/, 1, 4 )).to eq [ 0, 0, '{' ]
    expect(@b.pos_of_prev( /\[/, 5, 23 )).to eq [ 5, 9, '[' ]

    expect(@b.pos_of_prev( /q/, 4, 9 )).to be_nil
  end

  it 'knows the positions of matching pairs' do
    expect(@b.pos_of_pair_match( 0, 0 )).to eq [ 11, 0 ]
    expect(@b.pos_of_pair_match( 1, 5 )).to eq [ 10, 2 ]
    expect(@b.pos_of_pair_match( 3, 7 )).to eq [ 6, 4 ]
    expect(@b.pos_of_pair_match( 5, 9 )).to eq [ 5, 23 ]
    expect(@b.pos_of_pair_match( 5, 10 )).to eq [ 5, 15 ]

    expect(@b.pos_of_pair_match( 11, 0 )).to eq [ 0, 0 ]
    expect(@b.pos_of_pair_match( 10, 2 )).to eq [ 1, 5 ]
    expect(@b.pos_of_pair_match( 6, 4 )).to eq [ 3, 7 ]
    expect(@b.pos_of_pair_match( 5, 23 )).to eq [ 5, 9 ]
    expect(@b.pos_of_pair_match( 5, 15 )).to eq [ 5, 10 ]
  end

  it 'can handle mismatched pairs' do
    expect(@b.pos_of_pair_match( 17, 0 )).to eq [ nil, nil ]
    expect(@b.pos_of_pair_match( 18, 0 )).to eq [ nil, nil ]
    expect(@b.pos_of_pair_match( 19, 0 )).to eq [ nil, nil ]
    expect(@b.pos_of_pair_match( 21, 2 )).to eq [ 22, 0 ]
    expect(@b.pos_of_pair_match( 22, 0 )).to eq [ 21, 2 ]
    expect(@b.pos_of_pair_match( 5, 20 )).to eq [ nil, nil ]
    expect(@b.pos_of_pair_match( 5, 13 )).to eq [ nil, nil ]
    expect(@b.pos_of_pair_match( 23, 0 )).to eq [ nil, nil ]
  end
end

RSpec.describe 'Buffer#replace_all' do

  before do
    @d = $diakonos
    @b = @d.open_file(SAMPLE_FILE_LONGER)
  end

  after do
    @d.close_buffer @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'replaces all occurrences and returns the count' do
    num_replaced = @b.replace_all(/blah/, 'stuff')

    expect(num_replaced).to eq 45

    lines = @b.instance_variable_get(:@lines)
    blah_count = lines.count { |line| line.include?('blah') }
    stuff_count = lines.count { |line| line.include?('stuff') }
    expect(blah_count).to eq 0
    expect(stuff_count).to eq 45
  end
end
