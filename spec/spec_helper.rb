ENV['DIAKONOS_TESTING'] = '1'

require 'diakonos'

# TODO: Rewrite these as rspec custom expectations
def cursor_should_be_at( row, col )
  expect(@b.current_row).to eq row
  expect(@b.current_column).to eq col
end

# TODO: Rewrite these as rspec custom expectations
def numbered_buffer_should_be_named( number, name_expected )
  name = File.basename( @d.buffer_number_to_name( number ) )
  expect(name).to eq name_expected
end

# TODO: Rewrite these as rspec custom expectations
def selection_should_be( start_row, start_col, end_row, end_col )
  s = @b.selection_mark
  expect(s).not_to be_nil
  expect(s.start_row).to eq start_row
  expect(s.end_row).to eq end_row
  expect(s.start_col).to eq start_col
  expect(s.end_col).to eq end_col
end

__DIR__ = File.dirname( File.expand_path( __FILE__ ) )

RSpec.configure do |config|
  config.before do
    $diakonos = Diakonos::Diakonos.new [ '-e', 'quit', '--test' ]
    $diakonos.start
    $diakonos.parse_configuration_file( File.join( __DIR__, 'test-files', 'test.conf' ) )

    # The $keystrokes Array is used to buffer keystrokes to be typed during tests.
    # Multiple keystrokes are typed in rapid succession, and trigger the X windows
    # paste handling of Diakonos.
    # @see Diakonos::Diakonos#process_keystroke .
    $keystrokes = []
  end
end

if ! Object.const_defined? 'TEST_DIR'
  TEST_DIR = File.join( File.dirname( File.expand_path( __FILE__ ) ), 'test-files' )
end
if ! Object.const_defined? 'SAMPLE_FILE'
  SAMPLE_FILE = File.join( TEST_DIR, '/sample-file.rb' )
end
if ! Object.const_defined? 'SAMPLE_FILE_LONGER'
  SAMPLE_FILE_LONGER = File.join( TEST_DIR, '/longer-sample-file.rb' )
end
if ! Object.const_defined? 'SAMPLE_FILE_C'
  SAMPLE_FILE_C = File.join( TEST_DIR, '/sample-file.c' )
end
if ! Object.const_defined? 'SAMPLE_FILE_JS'
  SAMPLE_FILE_JS = File.join( TEST_DIR, '/sample-file.js' )
end
if ! Object.const_defined? 'BRACKET_FILE'
  BRACKET_FILE = File.join( TEST_DIR, '/bracket-file.rb' )
end
if ! Object.const_defined? 'TEMP_FILE'
  TEMP_FILE = File.join( TEST_DIR, '/temp-file.rb' )
end
if ! Object.const_defined? 'TEMP_FILE_C'
  TEMP_FILE_C = File.join( TEST_DIR, '/temp-file.c' )
end

SPEC_TMP = File.join(File.dirname(File.expand_path(__FILE__)), '..', 'tmp')

RSpec.shared_context 'virtual screen' do
  before do
    $use_virtual_screen = true
    cols = Curses.cols
    main_h = $diakonos.main_window_height
    $diakonos.win_main&.reset_virtual_screen(height: main_h, width: cols)
    $diakonos.win_status&.reset_virtual_screen(height: 1, width: cols)
    $diakonos.instance_variable_get(:@win_interaction)&.reset_virtual_screen(height: 1, width: cols)
    $diakonos.win_dock&.reset_virtual_screen(width: cols)
    $diakonos.win_line_numbers&.reset_virtual_screen(height: main_h)
    $diakonos.instance_variable_get(:@win_context)&.reset_virtual_screen(height: 1, width: cols)
  end

  after do
    $use_virtual_screen = false
  end
end

RSpec::Matchers.define :have_lines do |expected|
  match do |actual|
    actual == expected
  end

  failure_message do |actual|
    max_lines = [expected.size, actual.size].max
    lines = (0...max_lines).map { |i|
      exp = expected[i]
      act = actual[i]
      marker = (exp != act) ? ">>>" : "   "

      "#{marker} #{i.to_s.rjust(3)}: expected #{exp.inspect}, got #{act.inspect}"
    }

    "Lines differ:\n#{lines.join("\n")}"
  end
end
