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

end
