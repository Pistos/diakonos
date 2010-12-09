require_relative '../preparation'

describe 'A Diakonos user can' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
    cursor_should_be_at 0,0
  end

  after do
    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
  end

  it 'open a file at a specific line number' do
    @b = @d.open_file( "#{SAMPLE_FILE_LONGER}:45" )
    cursor_should_be_at 44, 0

    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
    @b = @d.open_file( "#{SAMPLE_FILE_LONGER}:50:" )
    cursor_should_be_at 49, 0

    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
    @b = @d.open_file( "#{SAMPLE_FILE_LONGER}:54: in `block in methodname'" )
    cursor_should_be_at 53, 0

    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
    @b = @d.open_file( "        from #{SAMPLE_FILE_LONGER}:57: in `block in methodname'" )
    cursor_should_be_at 56, 0

    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
    @b = @d.open_file( %{  File "#{SAMPLE_FILE_LONGER}", line 55, in decoration} )
    cursor_should_be_at 54, 0

    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
    @b = @d.open_file( " at #{SAMPLE_FILE_LONGER} line 61" )
    cursor_should_be_at 60, 0

  end

  it 'start up Diakonos and open a file at a specific line' do
    d2 = Diakonos::Diakonos.new [ '-e', 'quit', '--test', "#{SAMPLE_FILE_LONGER}:45" ]
    d2.start
    @b = d2.buffer_current
    cursor_should_be_at 44, 0
  end

  it 'renumber a buffer' do
    @d.open_file SAMPLE_FILE_LONGER
    @d.open_file SAMPLE_FILE_C

    numbered_buffer_should_be_named 2, 'sample-file.rb'
    numbered_buffer_should_be_named 3, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.c'

    @d.switch_to_buffer_number 2
    name = File.basename( @d.buffer_current.name )
    name.should.equal 'sample-file.rb'

    @d.renumber_buffer 4
    name = File.basename( @d.buffer_current.name )
    name.should.equal 'sample-file.rb'
    numbered_buffer_should_be_named 2, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 3, 'sample-file.c'
    numbered_buffer_should_be_named 4, 'sample-file.rb'

    @d.switch_to_buffer_number 3
    name = File.basename( @d.buffer_current.name )
    name.should.equal 'sample-file.c'

    @d.renumber_buffer 2
    name = File.basename( @d.buffer_current.name )
    name.should.equal 'sample-file.c'
    numbered_buffer_should_be_named 2, 'sample-file.c'
    numbered_buffer_should_be_named 3, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.rb'

    @d.switch_to_buffer_number 2
    name = File.basename( @d.buffer_current.name )
    name.should.equal 'sample-file.c'

    @d.renumber_buffer 2
    numbered_buffer_should_be_named 2, 'sample-file.c'
    numbered_buffer_should_be_named 3, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.rb'

    name = File.basename( @d.buffer_current.name )
    name.should.equal 'sample-file.c'
    @d.renumber_buffer 5
    numbered_buffer_should_be_named 2, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 3, 'sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.c'

    @d.renumber_buffer 99
    numbered_buffer_should_be_named 2, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 3, 'sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.c'

    @d.renumber_buffer 1
    numbered_buffer_should_be_named 1, 'sample-file.c'
    numbered_buffer_should_be_named 3, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.rb'

    should.raise do
      @d.renumber_buffer 0
    end
    numbered_buffer_should_be_named 1, 'sample-file.c'
    numbered_buffer_should_be_named 3, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.rb'

    should.raise do
      @d.renumber_buffer -1
    end
    numbered_buffer_should_be_named 1, 'sample-file.c'
    numbered_buffer_should_be_named 3, 'longer-sample-file.rb'
    numbered_buffer_should_be_named 4, 'sample-file.rb'
  end

end
