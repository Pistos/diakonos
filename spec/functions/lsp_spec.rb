require 'spec_helper'

RSpec.describe 'LSP functions' do
  let(:d) { $diakonos }
  let(:buffer) { d.open_file(SAMPLE_FILE) }
  let(:session) {
    instance_double(
      Diakonos::Lsp::Session,
      complete: nil,
      go_to_definition: nil,
      hover: nil,
    )
  }

  before do
    buffer.lsp_session = session
    allow(d).to receive(:set_iline).and_call_original
  end

  after do
    buffer.lsp_session = nil
    d.close_buffer buffer, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  describe '#complete_code' do
    context 'when the buffer has an LSP session' do
      it 'sends a complete request to the session' do
        d.complete_code

        expect(session).to have_received(:complete).with(
          buffer:,
          on_response: anything,
        )
      end
    end

    context 'when the buffer has no LSP session' do
      before do
        buffer.lsp_session = nil
      end

      it 'shows a message on the interaction line' do
        d.complete_code

        expect(d).to have_received(:set_iline).with('No LSP session for this buffer.')
      end
    end
  end

  describe 'handle_completion_result' do
    let(:callback) {
      captured_callback = nil
      allow(session).to receive(:complete) do |on_response:, **|
        captured_callback = on_response
      end
      d.complete_code

      captured_callback
    }

    before do
      buffer.cursor_to(18, 5, Diakonos::Buffer::DONT_DISPLAY)
      allow(d).to receive(:get_user_input)
    end

    after do
      if d.list_buffer
        d.close_list_buffer
      end
    end

    context 'with a CompletionList hash' do
      let(:result) {
        {
          isIncomplete: false,
          items: [
            { label: 'Sample' },
            { label: 'SampleClass' },
          ],
        }
      }

      it 'opens the list buffer with completion labels' do
        callback.call(result)

        expect(d.list_buffer).not_to be_nil
        list_contents = d.list_buffer.to_a
        expect(list_contents).to include('Sample')
        expect(list_contents).to include('SampleClass')
      end
    end

    context 'with a plain array of CompletionItems' do
      let(:result) {
        [
          { label: 'Sample' },
          { label: 'SampleClass' },
        ]
      }

      it 'opens the list buffer with completion labels' do
        callback.call(result)

        expect(d.list_buffer).not_to be_nil
        list_contents = d.list_buffer.to_a
        expect(list_contents).to include('Sample')
        expect(list_contents).to include('SampleClass')
      end
    end

    context 'with nil result' do
      it 'shows a message on the interaction line' do
        callback.call(nil)

        expect(d).to have_received(:set_iline).with('No completions.')
      end
    end

    context 'with an empty items list' do
      let(:result) {
        { isIncomplete: false, items: [] }
      }

      it 'shows a message on the interaction line' do
        callback.call(result)

        expect(d).to have_received(:set_iline).with('No completions.')
      end
    end

    context 'when the buffer has changed' do
      let(:result) {
        [{ label: 'Sample' }]
      }
      let(:other_buffer) { d.open_file(SAMPLE_FILE_C) }

      after do
        d.close_buffer other_buffer, to_all: Diakonos::CHOICE_NO_TO_ALL
      end

      it 'silently discards the result' do
        captured = callback
        other_buffer
        captured.call(result)

        expect(d.list_buffer).to be_nil
      end
    end

    context 'when the cursor row has changed' do
      let(:result) {
        [{ label: 'Sample' }]
      }

      before do
        buffer.cursor_to(0, 0, Diakonos::Buffer::DONT_DISPLAY)
      end

      it 'silently discards the result' do
        callback.call(result)

        expect(d.list_buffer).to be_nil
      end
    end
  end

  describe '#go_to_definition' do
    context 'when the buffer has an LSP session' do
      it 'sends a go_to_definition request to the session' do
        d.go_to_definition

        expect(session).to have_received(:go_to_definition).with(
          buffer:,
          on_response: anything,
        )
      end
    end

    context 'when the buffer has no LSP session' do
      before do
        buffer.lsp_session = nil
      end

      it 'shows a message on the interaction line' do
        d.go_to_definition

        expect(d).to have_received(:set_iline).with('No LSP session for this buffer.')
      end
    end
  end

  describe 'handle_definition_response' do
    let(:callback) {
      captured_callback = nil
      allow(session).to receive(:go_to_definition) do |on_response:, **|
        captured_callback = on_response
      end
      d.go_to_definition

      captured_callback
    }

    context 'with a single Location hash' do
      let(:location) {
        {
          uri: "file://#{SAMPLE_FILE}",
          range: {
            start: { line: 4, character: 2 },
            end: { line: 4, character: 10 },
          },
        }
      }

      it 'navigates to the location' do
        callback.call(location)

        expect(d.buffer_current.name).to eq SAMPLE_FILE
        expect(d.buffer_current.current_row).to eq 4
        expect(d.buffer_current.current_column).to eq 2
      end
    end

    context 'with an array of one Location' do
      let(:location) {
        {
          uri: "file://#{SAMPLE_FILE}",
          range: {
            start: { line: 5, character: 0 },
            end: { line: 5, character: 8 },
          },
        }
      }

      it 'navigates to the single location' do
        callback.call([location])

        expect(d.buffer_current.name).to eq SAMPLE_FILE
        expect(d.buffer_current.current_row).to eq 5
        expect(d.buffer_current.current_column).to eq 0
      end
    end

    context 'with an array of multiple Locations' do
      let(:locations) {
        [
          {
            uri: 'file:///first/file.rb',
            range: {
              start: { line: 10, character: 0 },
              end: { line: 10, character: 5 },
            },
          },
          {
            uri: 'file:///second/file.rb',
            range: {
              start: { line: 20, character: 4 },
              end: { line: 20, character: 12 },
            },
          },
        ]
      }

      before do
        allow(d).to receive(:get_user_input)
      end

      it 'opens the list buffer with formatted entries' do
        callback.call(locations)

        expect(d.list_buffer).not_to be_nil
        list_contents = d.list_buffer.to_a
        expect(list_contents).to include('/first/file.rb:11')
        expect(list_contents).to include('/second/file.rb:21')
      end

      after do
        if d.list_buffer
          d.close_list_buffer
        end
      end
    end

    context 'with nil result' do
      it 'shows a message on the interaction line' do
        callback.call(nil)

        expect(d).to have_received(:set_iline).with('No definition found.')
      end
    end

    context 'with an empty array' do
      it 'shows a message on the interaction line' do
        callback.call([])

        expect(d).to have_received(:set_iline).with('No definition found.')
      end
    end
  end

  describe '#hover' do
    context 'when the buffer has an LSP session' do
      it 'sends a hover request to the session' do
        d.hover

        expect(session).to have_received(:hover).with(
          buffer:,
          on_response: anything,
        )
      end
    end

    context 'when the buffer has no LSP session' do
      before do
        buffer.lsp_session = nil
      end

      it 'shows a message on the interaction line' do
        d.hover

        expect(d).to have_received(:set_iline).with('No LSP session for this buffer.')
      end
    end
  end

  describe 'handle_hover_result' do
    let(:callback) {
      captured_callback = nil
      allow(session).to receive(:hover) do |on_response:, **|
        captured_callback = on_response
      end
      d.hover

      captured_callback
    }

    after do
      d.send(:hide_dock)
    end

    context 'with a MarkupContent result' do
      let(:result) {
        {
          contents: {
            kind: 'markdown',
            value: "String\n\nA string class.",
          },
        }
      }

      it 'populates dock_lines from the hover content' do
        callback.call(result)

        expect(d.instance_variable_get(:@dock_lines)).to eq(
          ['String', '', 'A string class.']
        )
      end
    end

    context 'with a plain string result' do
      let(:result) {
        { contents: "just a string" }
      }

      it 'populates dock_lines' do
        callback.call(result)

        expect(d.instance_variable_get(:@dock_lines)).to eq(['just a string'])
      end
    end

    context 'with nil result' do
      it 'shows a message on the interaction line' do
        callback.call(nil)

        expect(d).to have_received(:set_iline).with('No hover information.')
      end
    end

    context 'with empty contents' do
      let(:result) {
        { contents: { kind: 'markdown', value: '' } }
      }

      it 'shows a message on the interaction line' do
        callback.call(result)

        expect(d).to have_received(:set_iline).with('No hover information.')
      end
    end
  end
end
