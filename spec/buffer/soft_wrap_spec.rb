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

  RSpec.shared_context "with top_line set" do
    before do
      buffer.instance_variable_set(:@top_line, top_line)
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

  describe '#num_visual_segments_for' do
    subject(:num_visual_segments_for) {
      buffer.num_visual_segments_for( 0 )
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

      include_context "with lines set up"

      context "for an empty line" do
        let(:lines) {
          [ '' ]
        }

        it { is_expected.to eq 1 }
      end

      context "for a line shorter than wrap_width" do
        let(:lines) {
          [ 'x' * (wrap_width - 1) ]
        }

        it { is_expected.to eq 1 }
      end

      context "for a line that exactly fills wrap_width" do
        let(:lines) {
          [ 'x' * wrap_width ]
        }

        it { is_expected.to eq 1 }
      end

      context "for a line one character longer than wrap_width" do
        let(:lines) {
          [ 'x' * (wrap_width + 1) ]
        }

        it { is_expected.to eq 2 }
      end

      context "for a long line" do
        let(:lines) {
          [ 'x' * (wrap_width * 3 + 5) ]
        }

        it { is_expected.to eq 4 }
      end

      context "for a line of tabs" do
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
      include_context "with lines set up"

      context 'with no tabs' do
        let(:lines) {
          [ 'a' * (wrap_width * 2 + 5) ]
        }

        it 'maps (segment, visual_x) back to the original buffer column' do
          original = wrap_width + 3

          expanded = buffer.tab_expanded_column( original, 0 )
          seg = buffer.visual_segment_index( expanded )
          vx = buffer.visual_x_of( expanded )

          expect(
            buffer.buffer_col_for_visual(
              row: 0,
              segment_index: seg,
              visual_x: vx
            )
          ).to eq original
        end
      end

      context 'with tabs' do
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

    include_context "with lines set up"

    context 'for expanded col 0' do
      let(:col) { 0 }

      let(:lines) {
        [ 'abc' ]
      }

      it { is_expected.to eq col }
    end

    context 'on a tab-free line' do
      let(:col) { 4 }
      let(:lines) {
        [ 'abcdef' ]
      }

      it { is_expected.to eq col }
    end

    context 'on a line beginning with a tab' do
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

  describe '#screen_position_of' do
    subject(:screen_position_of) {
      buffer.screen_position_of( row:, expanded_col: )
    }

    let(:row) { 0 }
    let(:expanded_col) { 0 }

    context 'when soft wrap is off' do
      before do
        disable_soft_wrap
      end

      context 'for the first character of the first visible row' do
        it { is_expected.to eq( y: 0, x: 0 ) }
      end

      context 'with @top_line offset' do
        let(:offset) { 3 }
        before do
          buffer.instance_variable_set(:@top_line, offset)
        end

        let(:row) { 5 }
        let(:expanded_col) { 7 }

        it('subtracts top_line and left_column') { is_expected.to eq(y: row - offset, x: 7) }
      end
    end

    context 'when soft wrap is on' do
      include_context "with lines set up"

      before do
        enable_soft_wrap
      end

      let(:num_full_visual_lines) { 3 }
      let(:lines) {
        [
          'a' * (wrap_width * num_full_visual_lines + 5),
          'short',
        ]
      }

      context 'on segment 0 of the first row' do
        let(:row) { 0 }
        let(:expanded_col) { 5 }

        it { is_expected.to eq( y: row, x: expanded_col ) }
      end

      context 'on segment 2 of the first row' do
        let(:row) { 0 }
        let(:expanded_col) { wrap_width * 2 + 3 }

        it { is_expected.to eq( y: 2, x: 3 ) }
      end

      context 'for a position on the second buffer row' do
        let(:row) { 1 }
        let(:expanded_col) { 2 }

        it('sums visual segments of preceding rows') {
          is_expected.to eq(y: num_full_visual_lines + row, x: 2)
        }
      end
    end
  end

  describe '#buffer_position_at_screen' do
    subject(:buffer_position_at_screen) {
      buffer.buffer_position_at_screen( screen_y:, screen_x: )
    }

    context 'when soft wrap is off' do
      before do
        disable_soft_wrap
      end

      context 'for an in-view position' do
        let(:screen_y) { 3 }
        let(:screen_x) { 5 }

        it 'adds top_line and left_column' do
          expect(buffer_position_at_screen).to eq(row: 3, col: 5)
        end
      end
    end

    context 'when soft wrap is on' do
      include_context "with lines set up"

      before do
        enable_soft_wrap
      end

      let(:lines) {
        [
          'a' * (wrap_width * 3 + 5),
          'short',
        ]
      }

      context 'clicking on a continuation row of a wrapped line' do
        let(:screen_y) { 2 }
        let(:screen_x) { 7 }

        it 'maps back to the same buffer row, deeper column' do
          expect(buffer_position_at_screen).to eq(
            row: 0,
            col: wrap_width * 2 + screen_x,
          )
        end
      end

      context 'clicking past the wrapped line onto the next buffer row' do
        let(:screen_y) { 4 }
        let(:screen_x) { 2 }

        it 'lands on the next buffer row' do
          expect(buffer_position_at_screen).to eq(row: 1, col: 2)
        end
      end
    end
  end

  describe '#pitch_view_visual' do
    include_context "with lines set up"

    before do
      enable_soft_wrap
    end

    let(:lines) {
      [
        'a' * (wrap_width * 3 + 5),  # 4 segments
        'b' * 3,                      # 1 segment
        'c' * (wrap_width + 1),       # 2 segments
        'd' * 3,                      # 1 segment
      ]
    }

    context 'with a positive amount that fits within the first row' do
      it 'advances top_line in buffer-row chunks while accounting for visual rows' do
        expect {
          buffer.pitch_view_visual(2)
        }.to change(buffer, :top_line).from(0).to(1)
      end

      it 'returns the visual rows actually shifted' do
        expect(buffer.pitch_view_visual(2)).to eq 4
      end
    end

    context 'with a negative amount when already at the top' do
      it 'returns 0 and leaves top_line unchanged' do
        expect {
          expect(buffer.pitch_view_visual(-3)).to eq 0
        }.not_to change(buffer, :top_line)
      end
    end

    context 'when soft wrap is off' do
      before do
        disable_soft_wrap
      end

      it 'returns 0 without altering top_line' do
        expect {
          expect(buffer.pitch_view_visual(5)).to eq 0
        }.not_to change(buffer, :top_line)
      end
    end
  end

  describe 'pan_view when soft wrap is on' do
    before do
      enable_soft_wrap
    end

    it 'is a no-op and reports no panning' do
      expect {
        expect(buffer.pan_view(5, Diakonos::Buffer::DONT_DISPLAY)).to eq 0
      }.not_to change(buffer, :left_column)
    end
  end

  describe '#after_soft_wrap_toggled' do
    include_context "with lines set up"

    let(:lines) {
      [ 'x' * (wrap_width * 2 + 3) ]
    }

    context 'toggling wrap on after a horizontal pan' do
      let(:target_column) { 5 }

      before do
        disable_soft_wrap
        buffer.instance_variable_set(:@last_row, 0)
        buffer.instance_variable_set(:@last_col, wrap_width + target_column)
        buffer.instance_variable_set(:@left_column, wrap_width)
        buffer.instance_variable_set(:@last_soft_wrap_state, false)
        enable_soft_wrap
      end

      it 'preserves the buffer cursor position' do
        buffer.after_soft_wrap_toggled

        expect(buffer.last_row).to eq 0
        expect(buffer.last_col).to eq wrap_width + target_column
      end

      it 'resets left_column to 0' do
        expect {
          buffer.after_soft_wrap_toggled
        }.to change(buffer, :left_column).from(wrap_width).to(0)
      end

      it 'recomputes screen coordinates onto the right visual segment' do
        buffer.after_soft_wrap_toggled

        expect(buffer.last_screen_y).to eq 1
        expect(buffer.last_screen_x).to eq target_column
      end
    end

    context 'when nothing has changed since the last call' do
      before do
        buffer.instance_variable_set(:@last_soft_wrap_state, buffer.soft_wrap?)
      end

      it 'leaves left_column alone' do
        buffer.instance_variable_set(:@left_column, 4)

        expect {
          buffer.after_soft_wrap_toggled
        }.not_to change(buffer, :left_column)
      end
    end
  end
end
