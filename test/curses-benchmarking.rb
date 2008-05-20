#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'
require 'better-benchmark'

class TC_Curses < Test::Unit::TestCase
  def setup
    @d = Diakonos::Diakonos.new [ '-e', 'quit' ]
    @d.start
  end
  
  def teardown
    system "reset"
    report @result
  end
  
  def report( result )
    puts
    puts( "Set 1 mean: %.3f s" % [ result[ :results1 ][ :mean ] ] )
    puts( "Set 1 std dev: %.3f" % [ result[ :results1 ][ :stddev ] ] )
    puts( "Set 2 mean: %.3f s" % [ result[ :results2 ][ :mean ] ] )
    puts( "Set 2 std dev: %.3f" % [ result[ :results2 ][ :stddev ] ] )
    puts "p.value: #{result[ :p ]}"
    puts "W: #{result[ :W ]}"
    puts(
      "The difference (%+.1f%%) %s statistically significant." % [
        ( ( result[ :results2 ][ :mean ] - result[ :results1 ][ :mean ] ) / result[ :results1 ][ :mean ] ) * 100,
        result[ :significant ] ? 'IS' : 'IS NOT'
      ]
    )
  end
  
  SAMPLE_FILE = File.dirname( File.expand_path( __FILE__ ) ) + '/../lib/diakonos.rb'
  NUM_INNER_ITERATIONS = 10
  def test_addstr
    @d.openFile( SAMPLE_FILE )
    b = Diakonos::Buffer.new( @d, SAMPLE_FILE )
    
    @result = Benchmark.compare_realtime {
      $diakonos_debug = true
      NUM_INNER_ITERATIONS.times do
        t = @d.current_buffer.display
        t.join
      end
    }.with {
      $diakonos_debug = false
      NUM_INNER_ITERATIONS.times do
        t = @d.current_buffer.display
        t.join
      end
    }
  end
end