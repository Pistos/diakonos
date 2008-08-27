#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_Buffer < Test::Unit::TestCase
  SAMPLE_FILE = File.dirname( File.expand_path( __FILE__ ) ) + '/sample-file.rb'
  
  def setup
    @d = Diakonos::Diakonos.new [ '-e', 'quit' ]
    @d.start
  end
  
  def teardown
    system "reset"
  end
  
  def test_selected_text
    @d.openFile( SAMPLE_FILE )
    b = Diakonos::Buffer.new( @d, SAMPLE_FILE, SAMPLE_FILE )
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
    @d.openFile SAMPLE_FILE
    b = Diakonos::Buffer.new( @d, SAMPLE_FILE, SAMPLE_FILE )
    b.find( [ /\bx\b/ ], :down, "\\0_", Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "        @x_ = 1", b[ 6 ]
    b.find( [ /\b(y)\b/ ], :down, "\\1_", Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "        @y_ = 2", b[ 7 ]
    b.find( [ /puts (\w+)/ ], :down, "print \\1", Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "        print x", b[ 11 ]
    b.find( [ /puts (\w+)/ ], :down, "puts \\1, \\1, \\1", Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "        puts y, y, y", b[ 12 ]
    b.find( [ /Sample\.(\w+)/ ], :down, "\\1\\\\\\1", Diakonos::CHOICE_YES_AND_STOP )
    assert_equal "s = new\\new", b[ 16 ]
  end
end