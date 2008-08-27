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
  
end