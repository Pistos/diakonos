require 'spec_helper'

RSpec.describe Diakonos::DockList do
  let(:items) { ['alpha', 'bravo', 'charlie', 'delta'] }
  let(:dock_list) { described_class.new(items:) }

  describe '#selected_item' do
    it 'returns the first item initially' do
      expect(dock_list.selected_item).to eq 'alpha'
    end
  end

  describe '#selected_index' do
    it 'starts at 0' do
      expect(dock_list.selected_index).to eq 0
    end
  end

  describe '#display_lines' do
    it 'returns the items array' do
      expect(dock_list.display_lines).to eq items
    end
  end

  describe '#next_item' do
    it 'advances the selection and returns the next item' do
      result = dock_list.next_item

      expect(result).to eq 'bravo'
      expect(dock_list.selected_index).to eq 1
    end

    it 'stays at the last item when already at the end' do
      3.times do
        dock_list.next_item
      end
      result = dock_list.next_item

      expect(result).to eq 'delta'
      expect(dock_list.selected_index).to eq 3
    end
  end

  describe '#previous_item' do
    it 'moves the selection back and returns the previous item' do
      2.times do
        dock_list.next_item
      end
      result = dock_list.previous_item

      expect(result).to eq 'bravo'
      expect(dock_list.selected_index).to eq 1
    end

    it 'stays at the first item when already at the beginning' do
      result = dock_list.previous_item

      expect(result).to eq 'alpha'
      expect(dock_list.selected_index).to eq 0
    end
  end
end
