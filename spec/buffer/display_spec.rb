require 'spec_helper'

RSpec.describe Diakonos::Buffer do
  LINES_PAST_END = 5

  describe '#display' do
    include_context 'virtual screen'

    subject(:display) { buffer.display }

    let(:buffer) { $diakonos.open_file(SAMPLE_FILE) }
    let(:line_count) { buffer.instance_variable_get(:@lines).length }

    after do
      $diakonos.close_buffer(
        buffer,
        to_all: Diakonos::CHOICE_NO_TO_ALL,
      )
    end

    context 'when @top_line has outrun the buffer length' do
      before do
        buffer.instance_variable_set(:@top_line, line_count + LINES_PAST_END)
      end

      it 'renders without raising' do
        expect { display }.not_to raise_error
      end
    end
  end
end
