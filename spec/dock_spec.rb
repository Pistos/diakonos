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

  describe '#show_info_dock' do
    context 'with content lines' do
      let(:lines) { ['Line one', 'Line two', 'Line three'] }

      it 'creates the dock window' do
        d.show_info_dock(lines:)

        expect(d.win_dock).not_to be_nil
      end

      it 'stores the dock lines' do
        d.show_info_dock(lines:)

        expect(d.instance_variable_get(:@dock_lines)).to eq lines
      end

      it 'reduces main_window_height by the dock height' do
        height_before = d.main_window_height
        d.show_info_dock(lines:)
        height_after = d.main_window_height

        expect(height_after).to eq(height_before - (lines.length + 1))
      end
    end
  end

  describe '#show_info_dock' do
    context 'showing_info_dock?' do
      it 'returns truthy when info dock is active' do
        d.show_info_dock(lines: ['Some content'])

        expect(d.showing_info_dock?).to be_truthy
      end

      it 'returns falsy when no dock is active' do
        expect(d.showing_info_dock?).to be_falsy
      end
    end
  end

  describe '#show_dock_list' do
    let(:items) { ['item one', 'item two', 'item three'] }

    it 'sets the dock list' do
      d.show_dock_list(items:, feature: 'grep')

      expect(d.showing_dock_list?).to be_truthy
    end

    it 'stores dock lines from the items' do
      d.show_dock_list(items:, feature: 'grep')

      expect(d.instance_variable_get(:@dock_lines)).to eq items
    end

    it 'is not an info dock' do
      d.show_dock_list(items:, feature: 'grep')

      expect(d.showing_info_dock?).to be_falsy
    end
  end

  describe '#hide_dock' do
    before do
      d.show_info_dock(lines: ['Some content'])
    end

    it 'removes the dock window' do
      d.send(:hide_dock)

      expect(d.win_dock).to be_nil
    end

    it 'clears the dock lines' do
      d.send(:hide_dock)

      expect(d.instance_variable_get(:@dock_lines)).to be_nil
    end

    it 'clears the dock list' do
      d.show_dock_list(items: ['a', 'b'], feature: 'grep')
      d.send(:hide_dock)

      expect(d.showing_dock_list?).to be_falsy
    end

    it 'restores main_window_height' do
      expected_height = Curses.lines - 2
      d.send(:hide_dock)

      expect(d.main_window_height).to eq expected_height
    end
  end

  describe '#dock_select' do
    let(:items) { (1..30).map { |i| "line #{i}" } }

    before do
      d.show_dock_list(items:, feature: 'grep')
    end

    it 'scrolls down to keep the selected index visible' do
      d.dock_select(index: 25)

      expect(d.instance_variable_get(:@dock_scroll_offset)).to be > 0
    end

    it 'scrolls back up when the selected index is above the viewport' do
      d.dock_select(index: 25)
      d.dock_select(index: 0)

      expect(d.instance_variable_get(:@dock_scroll_offset)).to eq 0
    end
  end
end
