require 'spec_helper'

RSpec.describe 'Dock pane' do
  let(:d) { $diakonos }

  before do
    d.open_file(SAMPLE_FILE)
  end

  after do
    d.send(:hide_dock)
    d.close_buffer d.buffer_current, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  describe '#show_dock' do
    context 'with content lines' do
      let(:lines) { ['Line one', 'Line two', 'Line three'] }

      it 'creates the dock window' do
        d.show_dock(lines:)

        expect(d.win_dock).to_not be_nil
      end

      it 'stores the dock lines' do
        d.show_dock(lines:)

        expect(d.instance_variable_get(:@dock_lines)).to eq lines
      end

      it 'reduces main_window_height by the dock height' do
        height_before = d.main_window_height
        d.show_dock(lines:)
        height_after = d.main_window_height

        expect(height_after).to eq(height_before - (lines.length + 1))
      end
    end
  end

  describe '#hide_dock' do
    before do
      d.show_dock(lines: ['Some content'])
    end

    it 'removes the dock window' do
      d.send(:hide_dock)

      expect(d.win_dock).to be_nil
    end

    it 'clears the dock lines' do
      d.send(:hide_dock)

      expect(d.instance_variable_get(:@dock_lines)).to be_nil
    end

    it 'restores main_window_height' do
      expected_height = Curses.lines - 2
      d.send(:hide_dock)

      expect(d.main_window_height).to eq expected_height
    end
  end
end
