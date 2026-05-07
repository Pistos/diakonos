require 'spec_helper'

RSpec.describe 'Diakonos::Buffer soft wrap helpers' do
  let(:buffer) {
    Diakonos::Buffer.new(
      'cursor' => { 'col' => 0, 'row' => 0 }
    )
  }
  let(:wrap_width) { buffer.wrap_width }

  RSpec.shared_context "with lines set up" do
    before do
      buffer.instance_variable_set(:@lines, lines)
    end
  end

  def enable_soft_wrap
    buffer.instance_variable_get( :@settings )[ 'view.wrap.soft' ] = true
  end

  def disable_soft_wrap
    buffer.instance_variable_get( :@settings )[ 'view.wrap.soft' ] = false
  end

  describe '#soft_wrap?' do
    context 'when the setting is false' do
      before do
        disable_soft_wrap
      end

      it 'returns false' do
        expect(buffer.soft_wrap?).to be false
      end
    end

    context 'when the setting is true' do
      before do
        enable_soft_wrap
      end

      it 'returns true' do
        expect(buffer.soft_wrap?).to be true
      end
    end
  end

  describe '#wrap_width' do
    it 'returns at least one column' do
      expect(buffer.wrap_width).to be > 0
    end

    context 'with no line-numbers gutter' do
      before do
        buffer.instance_variable_set( :@win_line_numbers, nil )
      end

      it 'matches the terminal width' do
        expect(buffer.wrap_width).to eq Curses.cols
      end
    end
  end

  describe '#visual_segments_for' do
    subject(:visual_segments_for) {
      buffer.visual_segments_for( 0 )
    }

    context 'when soft wrap is off' do
      before do
        disable_soft_wrap
      end

      context "for a long line" do
        include_context "with lines set up"

        let(:lines) {
          [ 'x' * (wrap_width * 3) ]
        }

        it { is_expected.to eq 1 }
      end
    end

    context 'when soft wrap is on' do
      before do
        enable_soft_wrap
      end

      context "for an empty line" do
        include_context "with lines set up"

        let(:lines) {
          [ '' ]
        }
        it { is_expected.to eq 1 }
      end

      context "for a line shorter than wrap_width" do
        include_context "with lines set up"

        let(:lines) {
          [ 'x' * (wrap_width - 1) ]
        }

        it { is_expected.to eq 1 }
      end

      context "for a line that exactly fills wrap_width" do
        include_context "with lines set up"

        let(:lines) {
          [ 'x' * wrap_width ]
        }

        it { is_expected.to eq 1 }
      end

      context "for a line one character longer than wrap_width" do
        include_context "with lines set up"

        let(:lines) {
          [ 'x' * (wrap_width + 1) ]
        }

        it { is_expected.to eq 2 }
      end

      context "for a long line" do
        include_context "with lines set up"

        let(:lines) {
          [ 'x' * (wrap_width * 3 + 5) ]
        }

        it { is_expected.to eq 4 }
      end

      context "for a line of tabs" do
        include_context "with lines set up"

        let(:tab_size) { buffer.instance_variable_get( :@tab_size ) }
        let(:lines) {
          [ "\t" * (wrap_width / tab_size + 1) ]
        }

        it { is_expected.to eq 2 }
      end
    end
  end

  context "with soft wrap on" do
    before do
      enable_soft_wrap
    end

    describe "#visual_segment_index" do
      subject(:visual_segment_index) {
        buffer.visual_segment_index( col )
      }

      context "for the first column" do
        let(:col) { 0 }

        it { is_expected.to eq 0 }
      end

      context "for the last visual column" do
        let(:col) { wrap_width - 1 }

        it { is_expected.to eq 0 }
      end

      context "for the last visual column" do
        let(:col) { wrap_width }

        it { is_expected.to eq 1 }
      end
    end

    describe "#visual_x_of" do
      subject(:visual_x_of) {
        buffer.visual_x_of( col )
      }

      context "for the first column" do
        let(:col) { 0 }

        it { is_expected.to eq 0 }
      end

      context "for the last visual column of the first segment" do
        let(:col) { wrap_width - 1 }

        it { is_expected.to eq wrap_width - 1 }
      end

      context "at the wrap boundary" do
        let(:col) { wrap_width }

        it { is_expected.to eq 0 }
      end

      context "partway into the second segment" do
        let(:col) { wrap_width + 7 }

        it { is_expected.to eq 7 }
      end
    end

    describe '#buffer_col_for_visual round-trips through tab_expanded_column' do
      context 'with no tabs' do
        include_context "with lines set up"

        let(:lines) {
          [ 'a' * (wrap_width * 2 + 5) ]
        }

        it 'maps (segment, visual_x) back to the original buffer column' do
          original = wrap_width + 3

          expanded = buffer.tab_expanded_column( original, 0 )
          seg = buffer.visual_segment_index( expanded )
          vx = buffer.visual_x_of( expanded )

          expect(buffer.buffer_col_for_visual( row: 0, segment_index: seg, visual_x: vx )).to eq original
        end
      end

      context 'with tabs' do
        include_context "with lines set up"

        let(:tab_size) { buffer.instance_variable_get( :@tab_size ) }
        let(:lines) {
          [ "\tabc\tdef" ]
        }

        it 'snaps to the start of a tab when visual_x lands inside one' do
          # First char is a tab — the position one column past start of
          # the tab's expansion should snap to buffer col 0 (the tab).
          expect(buffer.buffer_col_for_visual( row: 0, segment_index: 0, visual_x: 1 )).to eq 0
          # End of tab's expansion -> first non-tab char.
          expect(buffer.buffer_col_for_visual( row: 0, segment_index: 0, visual_x: tab_size )).to eq 1
        end
      end
    end
  end

  describe '#unexpand_tab_column' do
    subject(:unexpand_tab_column) {
      buffer.unexpand_tab_column( 0, col )
    }

    let(:tab_size) {
      buffer.instance_variable_get(:@tab_size)
    }

    context 'for expanded col 0' do
      let(:col) { 0 }

      include_context "with lines set up"

      let(:lines) {
        [ 'abc' ]
      }

      it { is_expected.to eq 0 }
    end

    context 'on a tab-free line' do
      include_context "with lines set up"

      let(:col) { 4 }
      let(:lines) {
        [ 'abcdef' ]
      }

      it { is_expected.to eq 4 }
    end

    context 'on a line beginning with a tab' do
      include_context "with lines set up"

      let(:lines) {
        [ "\tx" ]
      }

      context 'inside the tab expansion' do
        let(:col) { tab_size - 1 }

        it { is_expected.to eq 0 }
      end

      context 'at the tab stop' do
        let(:col) { tab_size }

        it { is_expected.to eq 1 }
      end
    end

    context 'on a line with mixed tabs and characters' do
      include_context "with lines set up"

      let(:lines) {
        [ "ab\tcd\te" ]
      }

      it 'inverts tab_expanded_column for arbitrary positions' do
        (0..6).each do |column|
          expanded = buffer.tab_expanded_column( column, 0 )
          expect(buffer.unexpand_tab_column( 0, expanded )).to eq column
        end
      end
    end
  end
end
