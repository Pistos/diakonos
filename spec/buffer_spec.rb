require 'spec_helper'

# TODO: Rewrite this as an rspec expectation
def check_word_at( row, col, expected_word )
  @b.cursor_to row, col
  expect(@b.word_under_cursor).to eq expected_word
end

# TODO: Rewrite this as an rspec expectation
def check_paragraph_at( row, col, expected_paragraph )
  @b.cursor_to row, col
  expect(@b.paragraph_under_cursor).to eq expected_paragraph
end

RSpec.describe 'A Diakonos::Buffer' do

  before do
    @b = Diakonos::Buffer.new( 'filepath' => SAMPLE_FILE )
  end

  it 'can provide selected text' do
    @b.anchor_selection( 0, 0 )
    @b.cursor_to( 3, 0 )
    clip = @b.copy_selection
    expect(clip).to eq(
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
    expect(@b[ 2 ]).to eq "# This is  a sample file used in the tests."
    @b.find( [ /@x\b/ ], :direction => :down, :replacement => "\\0_", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    expect(@b[ 8 ]).to eq "    @x_ = 1"
    @b.find( [ /@(y)\b/ ], :direction => :down, :replacement => "@\\1_", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    expect(@b[ 9 ]).to eq "    @y_ = 2"
    @b.find( [ /(\w+)\.inspect/ ], :direction => :down, :replacement => "print \\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    expect(@b[ 13 ]).to eq "    print x"
    @b.find( [ /(\w+)\.inspect/ ], :direction => :down, :replacement => "puts \\1, \\1, \\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    expect(@b[ 14 ]).to eq "    puts y, y, y"
    @b.find( [ /Sample\.(\w+)/ ], :direction => :down, :replacement => "\\1\\\\\\1", :auto_choice => Diakonos::CHOICE_YES_AND_STOP )
    expect(@b[ 18 ]).to eq "s = new\\new"
  end

  it 'knows indentation level' do
    expect(@b.indentation_level( 0 )).to eq 0
    expect(@b.indentation_level( 1 )).to eq 0
    expect(@b.indentation_level( 2 )).to eq 0
    expect(@b.indentation_level( 3 )).to eq 0
    expect(@b.indentation_level( 4 )).to eq 0
    expect(@b.indentation_level( 5 )).to eq 1
    expect(@b.indentation_level( 6 )).to eq 0
    expect(@b.indentation_level( 7 )).to eq 1
    expect(@b.indentation_level( 8 )).to eq 2
    expect(@b.indentation_level( 9 )).to eq 2
    expect(@b.indentation_level( 10 )).to eq 1
    expect(@b.indentation_level( 11 )).to eq 0
    expect(@b.indentation_level( 12 )).to eq 1
    expect(@b.indentation_level( 13 )).to eq 2
    expect(@b.indentation_level( 14 )).to eq 2
    expect(@b.indentation_level( 15 )).to eq 1
    expect(@b.indentation_level( 16 )).to eq 0
    expect(@b.indentation_level( 17 )).to eq 0
    expect(@b.indentation_level( 18 )).to eq 0
    expect(@b.indentation_level( 19 )).to eq 0
    expect(@b.indentation_level( 20 )).to eq 0
    expect(@b.indentation_level( 21 )).to eq 0
    expect(@b.indentation_level( 22 )).to eq 1
    expect(@b.indentation_level( 23 )).to eq 1
    expect(@b.indentation_level( 24 )).to eq 0
    expect(@b.indentation_level( 25 )).to eq 0

    indentation_file = File.join( TEST_DIR, 'indentation.test1' )
    b2 = Diakonos::Buffer.new( 'filepath' => indentation_file )
    indentation_file = File.join( TEST_DIR, 'indentation.test2' )
    b3 = Diakonos::Buffer.new( 'filepath' => indentation_file )

    expect(b2.indentation_level( 0 )).to eq 0
    expect(b3.indentation_level( 0 )).to eq 0
    expect(b2.indentation_level( 1 )).to eq 0
    expect(b3.indentation_level( 1 )).to eq 0
    expect(b2.indentation_level( 2 )).to eq 1
    expect(b3.indentation_level( 2 )).to eq 0
    expect(b2.indentation_level( 3 )).to eq 1
    expect(b3.indentation_level( 3 )).to eq 1
    expect(b2.indentation_level( 4 )).to eq 2
    expect(b3.indentation_level( 4 )).to eq 1
    expect(b2.indentation_level( 5 )).to eq 2
    expect(b3.indentation_level( 5 )).to eq 2
    expect(b2.indentation_level( 6 )).to eq 2
    expect(b3.indentation_level( 6 )).to eq 2
    expect(b2.indentation_level( 7 )).to eq 4
    expect(b3.indentation_level( 7 )).to eq 4
    expect(b2.indentation_level( 8 )).to eq 3
    expect(b3.indentation_level( 8 )).to eq 2
    expect(b2.indentation_level( 9 )).to eq 3
    expect(b3.indentation_level( 9 )).to eq 3
    expect(b2.indentation_level( 10 )).to eq 4
    expect(b3.indentation_level( 10 )).to eq 4
    expect(b2.indentation_level( 11 )).to eq 5
    expect(b3.indentation_level( 11 )).to eq 4
    expect(b2.indentation_level( 12 )).to eq 5
    expect(b3.indentation_level( 12 )).to eq 4
    expect(b2.indentation_level( 13 )).to eq 5
    expect(b3.indentation_level( 13 )).to eq 5
  end

  def indent_rows( from_row = 0, to_row = 20 )
    (from_row..to_row).each do |row|
      @b.parsed_indent  row: row, do_display: false
    end
  end

  it 'can indent smartly' do
    expected_file_contents = File.read(SAMPLE_FILE) + "\n"

    indent_rows
    @b.save_copy TEMP_FILE
    expect(File.read(TEMP_FILE)).to eq expected_file_contents

    @b.insert_string "   "
    @b.cursor_to( 5, 0 )
    @b.insert_string "   "
    @b.cursor_to( 7, 0 )
    @b.insert_string "   "
    @b.cursor_to( 8, 0 )
    @b.insert_string "   "
    @b.cursor_to( 14, 0 )
    @b.insert_string "   "
    @b.cursor_to( 20, 0 )
    @b.insert_string "   "

    @b.save_copy TEMP_FILE
    expect(File.read(TEMP_FILE)).not_to eq expected_file_contents

    indent_rows
    @b.save_copy TEMP_FILE
    expect(File.read(TEMP_FILE)).to eq expected_file_contents

    # -------

    @b = Diakonos::Buffer.new( 'filepath' => SAMPLE_FILE_C )

    indent_rows 0, @b.length-1
    @b.save_copy TEMP_FILE_C
    expect(File.read( TEMP_FILE_C )).to eq File.read( SAMPLE_FILE_C )

    @b.cursor_to( 3, 0 )
    @b.insert_string "    "
    @b.cursor_to( 10, 0 )
    @b.insert_string "    "
    @b.cursor_to( 12, 0 )
    @b.insert_string "    "

    @b.save_copy TEMP_FILE_C
    expect(File.read( TEMP_FILE_C )).not_to eq File.read( SAMPLE_FILE_C )

    indent_rows 0, 14
    @b.save_copy TEMP_FILE_C
    expect(File.read( TEMP_FILE_C )).to eq File.read( SAMPLE_FILE_C )
  end

  it 'can paste an Array of Strings' do
    lines = @b.to_a
    new_lines = [ 'line 1', 'line 2' ]
    @b.paste( new_lines + [ '' ] )
    lines2 = @b.to_a
    expect(lines2).to eq( new_lines + lines )
  end

  it 'can delete a line' do
    original_lines = @b.to_a
    expect(@b.delete_line).to eq '#!/usr/bin/env ruby'
    expect(@b.to_a).to eq original_lines[ 1..-1 ]
  end

  it 'knows the word under the cursor' do
    check_word_at 0, 16, 'ruby'
    check_word_at 2, 0, nil
    check_word_at 2, 2, 'This'
    check_word_at 2, 3, 'This'
    check_word_at 2, 4, 'This'
    check_word_at 2, 5, 'This'
    check_word_at 2, 6, nil
    check_word_at 2, 45, 'tests'
    check_word_at 2, 46, nil
    check_word_at 2, 47, nil
    check_word_at 3, 0, nil
    check_word_at 5, 14, nil
    check_word_at 5, 15, 'x'
    check_word_at 5, 16, nil
    check_word_at 14, 4, 'y'
    check_word_at 14, 5, nil
    check_word_at 14, 6, 'inspect'
    check_word_at 21, 0, nil
    check_word_at 22, 8, nil
    check_word_at 22, 9, nil
    check_word_at 26, 39, 'EOF'
    check_word_at 26, 40, nil
  end

  it 'knows the paragraph under the cursor' do
    check_paragraph_at 0, 0, [
      '#!/usr/bin/env ruby',
    ]
    check_paragraph_at 2, 0, [
      '# This is only a sample file used in the tests.',
    ]
    check_paragraph_at 4, 0, [
      'class Sample',
      '  attr_reader :x, :y',
    ]
    check_paragraph_at 7, 0, [
      '  def initialize',
      '    @x = 1',
      '    @y = 2',
      '  end',
    ]
    check_paragraph_at 14, 7, [
      '  def inspection',
      '    x.inspect',
      '    y.inspect',
      '  end',
      'end',
    ]
    check_paragraph_at 22, 7, [
      '{',
      '  :just => :a,',
      '  :test => :hash,',
      '}',
    ]
    check_paragraph_at 26, 12, [
      '# Comment at end, with no newline at EOF',
    ]
  end

end

RSpec.describe 'A Diakonos user' do

  before do
    @b = Diakonos::Buffer.new( 'filepath' => SAMPLE_FILE )
  end

  it 'can close XML tags' do
    @b.set_type 'html'

    @b.cursor_to 0,0
    @b.cursor_to_eol
    @b.carriage_return
    @b.paste "<div>"
    @b.close_code
    expect(@b[ @b.last_row ]).to eq '<div></div>'
    cursor_should_be_at @b.last_row, 5

    @b.cursor_to_eol
    @b.carriage_return
    @b.paste "<div><span>"
    @b.close_code
    expect(@b[ @b.last_row ]).to eq '<div><span></span>'
    cursor_should_be_at @b.last_row, 11

    @b.set_type 'xml'

    @b.cursor_to_eol
    @b.carriage_return
    @b.paste "<xsl:call-template>"
    @b.close_code
    expect(@b[ @b.last_row ]).to eq '<xsl:call-template></xsl:call-template>'
    cursor_should_be_at @b.last_row, 19

    @b.cursor_to_eol
    @b.carriage_return
    @b.paste "<xsl:call-template><xsl:choose>"
    @b.close_code
    expect(@b[ @b.last_row ]).to eq '<xsl:call-template><xsl:choose></xsl:choose>'
    cursor_should_be_at @b.last_row, 31

    @b.cursor_to_eol
    @b.carriage_return
    @b.paste "<xsl:call-template name='foo'>"
    @b.close_code
    expect(@b[ @b.last_row ]).to eq "<xsl:call-template name='foo'></xsl:call-template>"
    cursor_should_be_at @b.last_row, 30

    @b.cursor_to_eol
    @b.carriage_return
    @b.paste "<xsl:call-template name='foo'><xsl:if test='foo'>"
    @b.close_code
    expect(@b[ @b.last_row ]).to eq "<xsl:call-template name='foo'><xsl:if test='foo'></xsl:if>"
    cursor_should_be_at @b.last_row, 49
  end

end
