__DIR__ = File.dirname( File.expand_path( __FILE__ ) )
$LOAD_PATH.unshift "#{__DIR__}/../lib"

require 'bacon'
require 'diakonos'

$diakonos = Diakonos::Diakonos.new [ '-e', 'quit', '--test', ]
$diakonos.start
