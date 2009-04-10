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
if ! Object.const_defined? 'TEMP_FILE'
  TEMP_FILE = File.join( TEST_DIR, '/temp-file.rb' )
end

$diakonos = Diakonos::Diakonos.new [ '-e', 'quit', '--test', ]
$diakonos.start
$diakonos.parse_configuration_file( File.join( __DIR__, 'test-files', 'test.conf' ) )