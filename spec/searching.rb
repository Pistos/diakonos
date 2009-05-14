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

  it 'greps the open buffers' do
    dir = File.dirname( File.expand_path( __FILE__ ) )

    @d.actually_grep( 'inspect', @d.current_buffer )
    lines = File.readlines( @d.list_filename )
    lines[ 0 ].should.match %r(^sample-file\.rb:13:   def inspection {100,} \| #{dir}/test-files/sample-file\.rb:13\n$)
    lines[ 1 ].should.match %r(^sample-file\.rb:14:     x\.inspect {100,} \| #{dir}/test-files/sample-file\.rb:14\n$)
    lines[ 2 ].should.match %r(^sample-file\.rb:15:     y\.inspect {100,} \| #{dir}/test-files/sample-file\.rb:15\n$)
    lines[ 3 ].should.match %r(^sample-file\.rb:20: s\.inspection {100,} \| #{dir}/test-files/sample-file\.rb:20\n$)
    lines.size.should.equal 4
    @d.close_list_buffer
  end

end
