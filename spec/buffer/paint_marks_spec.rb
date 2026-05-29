require 'spec_helper'

RSpec.describe Diakonos::Buffer do
  describe '#paint_marks__range_of_mark_in_row' do
    subject(:range) {
      buffer.send(
        :paint_marks__range_of_mark_in_row,
        line_length:,
        row:,
        text_mark:,
      )
    }

    let(:buffer) {
      Diakonos::Buffer.new(
        'cursor' => { 'col' => 0, 'row' => 0 }
      )
    }
    let(:line_length) { 8 }
    let(:text_mark) {
      Diakonos::TextMark.new(
        Diakonos::Range.new(
          start_row,
          start_col,
          end_row,
          end_col,
        ),
        Curses::A_REVERSE,
      )
    }

    before do
      buffer.instance_variable_set(
        :@lines,
        [ 'abcdefgh', 'ijklmnop', 'qrstuvwx' ],
      )
    end

    context 'in normal selection mode' do
      before do
        buffer.instance_variable_set(:@selection_mode, :normal)
      end

      context 'when the row is outside the mark' do
        let(:end_col) { 4 }
        let(:end_row) { 2 }
        let(:row) { 0 }
        let(:start_col) { 2 }
        let(:start_row) { 1 }

        it { is_expected.to be_nil }
      end

      context 'when the mark begins and ends on the row' do
        let(:end_col) { 5 }
        let(:end_row) { 0 }
        let(:row) { 0 }
        let(:start_col) { 2 }
        let(:start_row) { 0 }

        it('begins and ends at the same columns') { is_expected.to eq(from: 2, to: 5) }
      end

      context 'on the first row of a multi-row mark' do
        let(:end_col) { 4 }
        let(:end_row) { 1 }
        let(:row) { 0 }
        let(:start_col) { 2 }
        let(:start_row) { 0 }

        it('runs from start_col to the end of the line') {
          is_expected.to eq(from: 2, to: line_length)
        }
      end

      context 'on the last row of a multi-row mark' do
        let(:end_col) { 4 }
        let(:end_row) { 1 }
        let(:row) { 1 }
        let(:start_col) { 2 }
        let(:start_row) { 0 }

        it('runs from the start of the line to end_col') {
          is_expected.to eq(from: 0, to: 4)
        }
      end

      context 'on a middle row of a multi-row mark' do
        let(:end_col) { 4 }
        let(:end_row) { 2 }
        let(:row) { 1 }
        let(:start_col) { 2 }
        let(:start_row) { 0 }

        it('covers the whole line') {
          is_expected.to eq(from: 0, to: line_length)
        }
      end
    end

    context 'in block selection mode' do
      before do
        buffer.instance_variable_set(:@selection_mode, :block)
      end

      let(:end_col) { 5 }
      let(:end_row) { 2 }
      let(:row) { 1 }
      let(:start_col) { 2 }
      let(:start_row) { 0 }

      it('uses the same columns on every row in span') {
        is_expected.to eq(from: 2, to: 5)
      }
    end

    describe '#paint_marks__paint' do
      include_context 'virtual screen'

      def paint
        buffer.send(
          :paint_marks__paint,
          base_y:,
          expanded_line:,
          from:,
          to:,
        )
      end

      def painted_row
        win_main.virtual_screen[base_y]
      end

      let(:base_y) { 7 }
      let(:buffer) {
        Diakonos::Buffer.new('cursor' => { 'col' => 0, 'row' => 0 })
      }
      let(:expanded_line) { 'abcdefghij' }
      let(:left_column) { 4 }
      let(:win_main) { $diakonos.win_main }

      before do
        buffer.instance_variable_set(:@win_main, win_main)
        buffer.instance_variable_set(:@left_column, left_column)
      end

      context 'when the range is within the horizontally-scrolled view' do
        let(:from) { 6 }
        let(:to) { 9 }

        it 'paints the substring at a column offset by left_column' do
          expect { paint }
          .to change { painted_row[from - left_column, to - from] }
          .from(' ' * (to - from))
          .to(expanded_line[from...to])
        end
      end

      context 'when the range is entirely left of the view' do
        let(:from) { 1 }
        let(:to) { 3 }

        it 'leaves the screen unchanged' do
          expect { paint }.not_to change { painted_row }
        end
      end
    end

    describe 'painting across soft-wrapped visual segments' do
      include_context 'virtual screen'

      subject(:screen) {
        buffer.display

        $diakonos.win_main.virtual_screen
      }

      let(:buffer) { $diakonos.open_file(SAMPLE_FILE) }
      let(:wrap_width) { buffer.wrap_width }

      before do
        buffer.instance_variable_get(:@settings)['view.wrap.soft'] = true
        buffer.instance_variable_set(:@top_line, 0)
        buffer.instance_variable_set(:@lines, [ line ])
      end

      after do
        $diakonos.close_buffer(
          buffer,
          to_all: Diakonos::CHOICE_NO_TO_ALL,
        )
      end

      def mark(
        end_col:,
        key:,
        start_col:
      )
        buffer.instance_variable_get(:@text_marks)[key] = [
          Diakonos::TextMark.new(
            Diakonos::Range.new(
              0,
              start_col,
              0,
              end_col,
            ),
            Curses::A_REVERSE,
          ),
        ]
      end

      context 'with a found mark beginning past the first segment' do
        let(:line) {
          ('.' * wrap_width) +
          'NEEDLE' +
          ('.' * 5)
        }

        before do
          mark(
            end_col: wrap_width + 'NEEDLE'.length,
            key: :found,
            start_col: wrap_width,
          )
        end

        it 'paints the match on the continuation row' do
          expect(screen[1]).to include('NEEDLE')
        end
      end

      context 'with a selection straddling a segment boundary' do
        let(:line) {
          ('.' * (wrap_width - 2)) +
          'BOUNDARY' +
          ('.' * 5
        ) }

        before do
          mark(
            end_col: wrap_width + 6,
            key: :selection,
            start_col: wrap_width - 2,
          )
        end

        it 'paints the portion that falls onto the continuation row' do
          expect(screen[1][0, 6]).to eq('UNDARY')
        end
      end
    end
  end
end
