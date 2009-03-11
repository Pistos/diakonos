#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_Buffer < Test::Unit::TestCase
  SAMPLE_FILE = File.dirname( File.expand_path( __FILE__ ) ) + '/sample-file.rb'

  def setup
    @d = Diakonos::Diakonos.new [ '-e', 'quit', '--test', ]
    @d.start
    @d.openFile( SAMPLE_FILE )
    @b = Diakonos::Buffer.new( @d, SAMPLE_FILE, SAMPLE_FILE )
  end

  def teardown
    @d.quit
    system "reset"
  end

  def test_selected_text
    @d.anchorSelection
    @d.cursorDown
    @d.cursorDown
    @d.cursorDown
    @d.copySelection
    assert_equal(
      [
        "#!/usr/bin/env ruby",
        "",
        "# This is only a sample file used in the tests.",
        ""
      ],
      @d.clipboard.clip
    )
  end

  def test_replace
    @b.find( [ /only/ ], :direction => :down, :replacement => "\\2", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "# This is  a sample file used in the tests.", @b[ 2 ]
    @b.find( [ /\bx\b/ ], :direction => :down, :replacement => "\\0_", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "    @x_ = 1", @b[ 6 ]
    @b.find( [ /\b(y)\b/ ], :direction => :down, :replacement => "\\1_", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "    @y_ = 2", @b[ 7 ]
    @b.find( [ /puts (\w+)/ ], :direction => :down, :replacement => "print \\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "    print x", @b[ 11 ]
    @b.find( [ /puts (\w+)/ ], :direction => :down, :replacement => "puts \\1, \\1, \\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "    puts y, y, y", @b[ 12 ]
    @b.find( [ /Sample\.(\w+)/ ], :direction => :down, :replacement => "\\1\\\\\\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "s = new\\new", @b[ 16 ]
  end

  def test_indentation_level
    assert_equal 0, @b.indentation_level( 0 )
    assert_equal 0, @b.indentation_level( 1 )
    assert_equal 0, @b.indentation_level( 2 )
    assert_equal 0, @b.indentation_level( 3 )
    assert_equal 0, @b.indentation_level( 4 )
    assert_equal 1, @b.indentation_level( 5 )
    assert_equal 2, @b.indentation_level( 6 )
    assert_equal 2, @b.indentation_level( 7 )
    assert_equal 1, @b.indentation_level( 8 )
    assert_equal 0, @b.indentation_level( 9 )
    assert_equal 1, @b.indentation_level( 10 )
    assert_equal 2, @b.indentation_level( 11 )
    assert_equal 2, @b.indentation_level( 12 )
    assert_equal 1, @b.indentation_level( 13 )
    assert_equal 0, @b.indentation_level( 14 )
    assert_equal 0, @b.indentation_level( 15 )
    assert_equal 0, @b.indentation_level( 16 )
    assert_equal 0, @b.indentation_level( 17 )
    assert_equal 0, @b.indentation_level( 18 )
  end
end