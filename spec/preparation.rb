__DIR__ = File.dirname( File.expand_path( __FILE__ ) )
lib_dir = "#{__DIR__}/../lib"
if $LOAD_PATH[ 0 ] != lib_dir
  $LOAD_PATH.unshift lib_dir
end

require 'bacon'
require 'diakonos'

if ! Object.const_defined? 'TEST_DIR'
  TEST_DIR = File.join( File.dirname( File.expand_path( __FILE__ ) ), 'test-files' )
end
if ! Object.const_defined? 'SAMPLE_FILE'
  SAMPLE_FILE = File.join( TEST_DIR, '/sample-file.rb' )
end
if ! Object.const_defined? 'SAMPLE_FILE_LONGER'
  SAMPLE_FILE_LONGER = File.join( TEST_DIR, '/longer-sample-file.rb' )
end
if ! Object.const_defined? 'SAMPLE_FILE_C'
  SAMPLE_FILE_C = File.join( TEST_DIR, '/sample-file.c' )
end
if ! Object.const_defined? 'BRACKET_FILE'
  BRACKET_FILE = File.join( TEST_DIR, '/bracket-file.rb' )
end
if ! Object.const_defined? 'TEMP_FILE'
  TEMP_FILE = File.join( TEST_DIR, '/temp-file.rb' )
end
if ! Object.const_defined? 'TEMP_FILE_C'
  TEMP_FILE_C = File.join( TEST_DIR, '/temp-file.c' )
end

def cursor_should_be_at( row, col )
  @b.current_row.should.equal row
  @b.current_column.should.equal col
end

def numbered_buffer_should_be_named( number, name_expected )
  name = File.basename( @d.buffer_number_to_name( number ) )
  name.should.equal name_expected
end


if $diakonos.nil?
  $diakonos = Diakonos::Diakonos.new [ '-e', 'quit', '--test', ]
  $diakonos.start
  $diakonos.parse_configuration_file( File.join( __DIR__, 'test-files', 'test.conf' ) )
end
