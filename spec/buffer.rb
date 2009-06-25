require 'spec/preparation'

def check_word_at( row, col, expected_word )
  @b.cursor_to row, col
  @b.word_under_cursor.should.equal expected_word
end

describe 'A Diakonos::Buffer' do

  before do
    @b = Diakonos::Buffer.new( $diakonos, SAMPLE_FILE, SAMPLE_FILE )
  end

  it 'can provide selected text' do
    @b.anchor_selection( 0, 0 )
    @b.cursor_to( 3, 0 )
    clip = @b.copy_selection
    clip.should.equal(
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
    @b.indentation_level( 6 ).should.equal 0
    @b.indentation_level( 7 ).should.equal 1
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
    @b.indentation_level( 21 ).should.equal 0
    @b.indentation_level( 22 ).should.equal 1
    @b.indentation_level( 23 ).should.equal 1
    @b.indentation_level( 24 ).should.equal 0
    @b.indentation_level( 25 ).should.equal 0

    indentation_file = File.join( TEST_DIR, 'indentation.test1' )
    b2 = Diakonos::Buffer.new( $diakonos, indentation_file, indentation_file )
    indentation_file = File.join( TEST_DIR, 'indentation.test2' )
    b3 = Diakonos::Buffer.new( $diakonos, indentation_file, indentation_file )

    b2.indentation_level( 0 ).should.equal 0
    b3.indentation_level( 0 ).should.equal 0
    b2.indentation_level( 1 ).should.equal 0
    b3.indentation_level( 1 ).should.equal 0
    b2.indentation_level( 2 ).should.equal 1
    b3.indentation_level( 2 ).should.equal 0
    b2.indentation_level( 3 ).should.equal 1
    b3.indentation_level( 3 ).should.equal 1
    b2.indentation_level( 4 ).should.equal 2
    b3.indentation_level( 4 ).should.equal 1
    b2.indentation_level( 5 ).should.equal 2
    b3.indentation_level( 5 ).should.equal 2
    b2.indentation_level( 6 ).should.equal 2
    b3.indentation_level( 6 ).should.equal 2
    b2.indentation_level( 7 ).should.equal 4
    b3.indentation_level( 7 ).should.equal 4
    b2.indentation_level( 8 ).should.equal 3
    b3.indentation_level( 8 ).should.equal 2
    b2.indentation_level( 9 ).should.equal 3
    b3.indentation_level( 9 ).should.equal 3
    b2.indentation_level( 10 ).should.equal 4
    b3.indentation_level( 10 ).should.equal 4
    b2.indentation_level( 11 ).should.equal 5
    b3.indentation_level( 11 ).should.equal 4
    b2.indentation_level( 12 ).should.equal 5
    b3.indentation_level( 12 ).should.equal 4
    b2.indentation_level( 13 ).should.equal 5
    b3.indentation_level( 13 ).should.equal 5
  end

  def indent_rows( from_row = 0, to_row = 20 )
    (from_row..to_row).each do |row|
      @b.parsed_indent row, ::Diakonos::Buffer::DONT_DISPLAY
    end
  end

  it 'can indent smartly' do
    indent_rows
    @b.save_copy TEMP_FILE
    File.read( TEMP_FILE ).should.equal File.read( SAMPLE_FILE )

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
    File.read( TEMP_FILE ).should.not.equal File.read( SAMPLE_FILE )

    indent_rows
    @b.save_copy TEMP_FILE
    File.read( TEMP_FILE ).should.equal File.read( SAMPLE_FILE )

    # -------

    @b = Diakonos::Buffer.new( $diakonos, SAMPLE_FILE_C, SAMPLE_FILE_C )

    indent_rows 0, 14
    @b.save_copy TEMP_FILE_C
    File.read( TEMP_FILE_C ).should.equal File.read( SAMPLE_FILE_C )

    @b.cursor_to( 3, 0 )
    @b.insert_string "    "
    @b.cursor_to( 10, 0 )
    @b.insert_string "    "
    @b.cursor_to( 12, 0 )
    @b.insert_string "    "

    @b.save_copy TEMP_FILE_C
    File.read( TEMP_FILE_C ).should.not.equal File.read( SAMPLE_FILE_C )

    indent_rows 0, 14
    @b.save_copy TEMP_FILE_C
    File.read( TEMP_FILE_C ).should.equal File.read( SAMPLE_FILE_C )
  end

  it 'can paste an Array of Strings' do
    lines = @b.to_a
    new_lines = [ 'line 1', 'line 2' ]
    @b.paste( new_lines + [ '' ] )
    lines2 = @b.to_a
    lines2.should.equal( new_lines + lines )
  end

  it 'can delete a line' do
    original_lines = @b.to_a
    @b.delete_line.should.equal '#!/usr/bin/env ruby'
    @b.to_a.should.equal original_lines[ 1..-1 ]
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

end