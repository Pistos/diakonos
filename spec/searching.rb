require_relative 'preparation'

describe 'A Diakonos user' do

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
    lines[ 0 ].should.match %r(^sample-file\.rb:13:   def inspection {100,} \| #{dir}/test-files/sample-file\.rb:13\n$)
    lines[ 1 ].should.match %r(^sample-file\.rb:14:     x\.inspect {100,} \| #{dir}/test-files/sample-file\.rb:14\n$)
    lines[ 2 ].should.match %r(^sample-file\.rb:15:     y\.inspect {100,} \| #{dir}/test-files/sample-file\.rb:15\n$)
    lines[ 3 ].should.match %r(^sample-file\.rb:20: s\.inspection {100,} \| #{dir}/test-files/sample-file\.rb:20\n$)
    lines.size.should.equal 4
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

end

describe 'A Diakonos Buffer' do

  before do
    @d = $diakonos
    @b = @d.open_file( BRACKET_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_buffer  @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'can find next closest characters' do
    @b.pos_of_next( /x/, 0, 0 ).should.equal [ 1, 2, 'x' ]
    @b.pos_of_next( /a/, 0, 0 ).should.equal [ 2, 4, 'a' ]
    @b.pos_of_next( /b/, 0, 0 ).should.equal [ 3, 4, 'b' ]
    @b.pos_of_next( /\}/, 0, 0 ).should.equal [ 5, 15, '}' ]

    @b.pos_of_next( /:/, 1, 2 ).should.equal [ 1, 3, ':' ]
    @b.pos_of_next( /a/, 2, 4 ).should.equal [ 2, 4, 'a' ]
    @b.pos_of_next( /\]/, 5, 9 ).should.equal [ 5, 23, ']' ]

    @b.pos_of_next( /q/, 0, 0 ).should.be.nil
  end

  it 'can find previous closest characters' do
    @b.pos_of_prev( /x/, 4, 9 ).should.equal [ 1, 2, 'x' ]
    @b.pos_of_prev( /a/, 4, 9 ).should.equal [ 2, 4, 'a' ]
    @b.pos_of_prev( /:/, 4, 7 ).should.equal [ 4, 7, ':' ]

    @b.pos_of_prev( /c/, 4, 7 ).should.equal [ 4, 6, 'c' ]
    @b.pos_of_prev( /\{/, 1, 4 ).should.be.equal [ 0, 0, '{' ]
    @b.pos_of_prev( /\[/, 5, 23 ).should.equal [ 5, 9, '[' ]

    @b.pos_of_prev( /q/, 4, 9 ).should.be.nil
  end

  it 'knows the positions of matching pairs' do
    @b.pos_of_pair_match( 0, 0 ).should.equal [ 11, 0 ]
    @b.pos_of_pair_match( 1, 5 ).should.equal [ 10, 2 ]
    @b.pos_of_pair_match( 3, 7 ).should.equal [ 6, 4 ]
    @b.pos_of_pair_match( 5, 9 ).should.equal [ 5, 23 ]
    @b.pos_of_pair_match( 5, 10 ).should.equal [ 5, 15 ]

    @b.pos_of_pair_match( 11, 0 ).should.equal [ 0, 0 ]
    @b.pos_of_pair_match( 10, 2 ).should.equal [ 1, 5 ]
    @b.pos_of_pair_match( 6, 4 ).should.equal [ 3, 7 ]
    @b.pos_of_pair_match( 5, 23 ).should.equal [ 5, 9 ]
    @b.pos_of_pair_match( 5, 15 ).should.equal [ 5, 10 ]
  end

  it 'can handle mismatched pairs' do
    @b.pos_of_pair_match( 17, 0 ).should.equal [ nil, nil ]
    @b.pos_of_pair_match( 18, 0 ).should.equal [ nil, nil ]
    @b.pos_of_pair_match( 19, 0 ).should.equal [ nil, nil ]
    @b.pos_of_pair_match( 21, 2 ).should.equal [ 22, 0 ]
    @b.pos_of_pair_match( 22, 0 ).should.equal [ 21, 2 ]
    @b.pos_of_pair_match( 5, 20 ).should.equal [ nil, nil ]
    @b.pos_of_pair_match( 5, 13 ).should.equal [ nil, nil ]
    @b.pos_of_pair_match( 23, 0 ).should.equal [ nil, nil ]
  end
end
