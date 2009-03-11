require 'spec/preparation'

describe 'A Diakonos::Buffer' do
  SAMPLE_FILE = File.dirname( File.expand_path( __FILE__ ) ) + '/sample-file.rb'

  before do
    @d = $diakonos
    @d.openFile( SAMPLE_FILE )
    @b = Diakonos::Buffer.new( @d, SAMPLE_FILE, SAMPLE_FILE )
  end

  after do
  end

  it 'can put a selection in a clipboard' do
    @d.anchorSelection
    @d.cursorDown
    @d.cursorDown
    @d.cursorDown
    @d.copySelection
    @d.clipboard.clip.should.equal(
      [
        "#!/usr/bin/env ruby",
        "",
        "# This is only a sample file used in the tests.",
        ""
      ]
    )
  end

  it 'can replace text' do
    @b.find( [ /only/ ], :direction => :down, :replacement => "\\2", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    @b[ 2 ].should.equal "# This is  a sample file used in the tests."
    @b.find( [ /@x\b/ ], :direction => :down, :replacement => "\\0_", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    @b[ 8 ].should.equal "    @x_ = 1"
    @b.find( [ /@(y)\b/ ], :direction => :down, :replacement => "@\\1_", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    @b[ 9 ].should.equal "    @y_ = 2"
    @b.find( [ /(\w+)\.inspect/ ], :direction => :down, :replacement => "print \\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    @b[ 13 ].should.equal "    print x"
    @b.find( [ /(\w+)\.inspect/ ], :direction => :down, :replacement => "puts \\1, \\1, \\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    @b[ 14 ].should.equal "    puts y, y, y"
    @b.find( [ /Sample\.(\w+)/ ], :direction => :down, :replacement => "\\1\\\\\\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    @b[ 18 ].should.equal "s = new\\new"
  end

  it 'knows indentation level' do
    @b.indentation_level( 0 ).should.equal 0
    @b.indentation_level( 1 ).should.equal 0
    @b.indentation_level( 2 ).should.equal 0
    @b.indentation_level( 3 ).should.equal 0
    @b.indentation_level( 4 ).should.equal 0
    @b.indentation_level( 5 ).should.equal 1
    @b.indentation_level( 6 ).should.equal 2
    @b.indentation_level( 7 ).should.equal 2
    @b.indentation_level( 8 ).should.equal 2
    @b.indentation_level( 9 ).should.equal 2
    @b.indentation_level( 10 ).should.equal 1
    @b.indentation_level( 11 ).should.equal 0
    @b.indentation_level( 12 ).should.equal 1
    @b.indentation_level( 13 ).should.equal 2
    @b.indentation_level( 14 ).should.equal 2
    @b.indentation_level( 15 ).should.equal 1
    @b.indentation_level( 16 ).should.equal 0
    @b.indentation_level( 17 ).should.equal 0
    @b.indentation_level( 18 ).should.equal 0
    @b.indentation_level( 19 ).should.equal 0
    @b.indentation_level( 20 ).should.equal 0
  end
end