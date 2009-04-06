require 'spec/preparation'

describe 'Diakonos' do
  TEST_DIR = File.join( File.dirname( File.expand_path( __FILE__ ) ), 'test-files' )
  SAMPLE_FILE = File.join( TEST_DIR, '/sample-file.rb' )
  TEMP_FILE = File.join( TEST_DIR, '/temp-file.rb' )

  before do
    @d = $diakonos
    @b = @d.openFile( SAMPLE_FILE )
  end

  it 'can cut consecutive lines into an internal clipboard' do
    original_lines = @b.to_a

    @d.cursorBOF
    @d.deleteAndStoreLine
    @d.last_commands << 'deleteAndStoreLine'
    @d.clipboard.clip.should.equal( [
      '#!/usr/bin/env ruby',
      '',
    ] )
    @d.deleteAndStoreLine
    @d.last_commands << 'deleteAndStoreLine'
    @d.clipboard.clip.should.equal( [
      '#!/usr/bin/env ruby',
      '',
      '',
    ] )
    @d.deleteAndStoreLine
    @d.last_commands << 'deleteAndStoreLine'
    @d.clipboard.clip.should.equal( [
      '#!/usr/bin/env ruby',
      '',
      '# This is only a sample file used in the tests.',
      '',
    ] )
    @b.to_a.should.not.equal original_lines

    @d.paste
    @b.to_a.should.equal original_lines
  end

  it 'can cut consecutive lines to Klipper' do
    original_lines = @b.to_a

    @d.cursorBOF
    @d.delete_and_store_line_to_klipper
    @d.last_commands << 'delete_and_store_line_to_klipper'
    @b.to_a.should.equal original_lines[ 1..-1 ]
    @d.delete_and_store_line_to_klipper
    @d.last_commands << 'delete_and_store_line_to_klipper'
    @b.to_a.should.equal original_lines[ 2..-1 ]
    @d.delete_and_store_line_to_klipper
    @d.last_commands << 'delete_and_store_line_to_klipper'
    @b.to_a.should.equal original_lines[ 3..-1 ]

    @d.paste
    @b.to_a.should.equal original_lines
  end
end