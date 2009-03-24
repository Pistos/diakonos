require 'spec/preparation'

describe 'Diakonos' do
  SAMPLE_FILE = File.dirname( File.expand_path( __FILE__ ) ) + '/sample-file.rb'
  TEMP_FILE = File.dirname( File.expand_path( __FILE__ ) ) + '/temp-file.rb'

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

  # it 'can cut consecutive lines to Klipper' do
    # @d.cursorBOF
    # 3.times { @d.delete_and_store_line_to_klipper }
    # @b.saveCopy TEMP_FILE
    # File.read( TEMP_FILE ).should.not.equal @sample
#
    # @d.paste_from_klipper
    # @b.saveCopy TEMP_FILE
    # File.read( TEMP_FILE ).should.equal @sample
  # end
end