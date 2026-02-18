require 'spec_helper'

RSpec.describe Diakonos::Lsp::Session do
  let(:queue) { Thread::Queue.new }
  let(:server) {
    instance_double(
      Diakonos::Lsp::Server,
      next_request_id: 1,
      queue:,
      write: nil,
    )
  }
  let(:session) { described_class.new(server:) }

  before do
    allow($diakonos).to receive(:log)
  end

  describe '#send_request' do
    it 'writes a message with an ID to the server' do
      session.send_request(method: 'textDocument/hover', params: { position: 1 })

      expect(server).to have_received(:write).with(
        message: {
          id: 1,
          method: 'textDocument/hover',
          params: { position: 1 },
        },
      )
    end

    it 'returns the request ID' do
      result = session.send_request(method: 'textDocument/hover')

      expect(result).to eq 1
    end
  end

  describe '#hover' do
    let(:buffer) {
      instance_double(
        Diakonos::Buffer,
        last_col: 7,
        last_row: 3,
        lsp_uri: 'file:///project/bar.rb',
      )
    }
    let(:on_result) { instance_double(Proc) }

    it 'sends a textDocument/hover request with cursor position' do
      session.hover(buffer:, on_result:)

      expect(server).to have_received(:write).with(
        message: {
          id: 1,
          method: 'textDocument/hover',
          params: {
            position: {
              character: 7,
              line: 3,
            },
            textDocument: {
              uri: 'file:///project/bar.rb',
            },
          },
        },
      )
    end
  end

  describe '#go_to_definition' do
    let(:buffer) {
      instance_double(
        Diakonos::Buffer,
        last_col: 10,
        last_row: 5,
        lsp_uri: 'file:///project/foo.rb',
      )
    }
    let(:on_result) { instance_double(Proc) }

    it 'sends a textDocument/definition request with cursor position' do
      session.go_to_definition(buffer:, on_result:)

      expect(server).to have_received(:write).with(
        message: {
          id: 1,
          method: 'textDocument/definition',
          params: {
            position: {
              character: 10,
              line: 5,
            },
            textDocument: {
              uri: 'file:///project/foo.rb',
            },
          },
        },
      )
    end
  end

  describe '#send_notification' do
    it 'writes a message without an ID to the server' do
      session.send_notification(
        method: 'textDocument/didOpen',
        params: { uri: 'file:///foo.rb' },
      )

      expect(server).to have_received(:write).with(
        message: {
          method: 'textDocument/didOpen',
          params: { uri: 'file:///foo.rb' },
        },
      )
    end
  end

  describe '#process_queue' do
    context 'when the queue has a response matching a pending request' do
      before do
        session.send_request(method: 'textDocument/hover')
        queue.push({ id: 1, result: { contents: 'String' } })
      end

      it 'logs the response with the original method name' do
        session.process_queue

        expect($diakonos).to have_received(:log).with(
          %r{LSP response for textDocument/hover \(id=1\)}
        )
      end
    end

    context 'when the response has an on_response callback' do
      let(:callback) { instance_double(Proc) }

      before do
        allow(callback).to receive(:call)
        session.send_request(
          method: 'textDocument/definition',
          on_response: callback,
        )
        queue.push({ id: 1, result: { uri: 'file:///foo.rb' } })
      end

      it 'invokes the callback with the result' do
        session.process_queue

        expect(callback).to have_received(:call).with({ uri: 'file:///foo.rb' })
      end
    end

    context 'when the queue has a response with no matching request' do
      before do
        queue.push({ id: 999, result: {} })
      end

      it 'logs the response as unknown' do
        session.process_queue

        expect($diakonos).to have_received(:log).with(/unknown request id=999/)
      end
    end

    context 'when the queue has a notification' do
      before do
        queue.push({ method: 'textDocument/publishDiagnostics', params: { uri: 'file:///foo.rb' } })
      end

      it 'logs the notification method' do
        session.process_queue

        expect($diakonos).to have_received(:log).with(%r{LSP notification: textDocument/publishDiagnostics})
      end
    end

    context 'when the queue has a server request' do
      before do
        queue.push({ id: 5, method: 'window/workDoneProgress/create', params: { token: 'abc' } })
      end

      it 'logs the server request' do
        session.process_queue

        expect($diakonos).to have_received(:log).with(
          %r{LSP server request: window/workDoneProgress/create \(id=5\)}
        )
      end
    end

    context 'when the queue is empty' do
      it 'returns without blocking' do
        session.process_queue

        expect($diakonos).to have_received(:log).exactly(0).times
      end
    end
  end
end
