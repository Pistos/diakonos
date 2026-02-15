require 'spec_helper'

RSpec.describe Diakonos::Lsp::Session do
  let(:queue) { Thread::Queue.new }
  let(:server) { instance_double(Diakonos::Lsp::Server, queue:) }
  let(:session) { described_class.new(server:) }

  describe '#process_queue' do
    context 'when the queue has messages' do
      before do
        queue.push({ method: 'textDocument/publishDiagnostics' })
        queue.push({ method: 'window/logMessage' })
      end

      it 'drains all messages from the queue' do
        session.process_queue

        expect(queue).to be_empty
      end

      it 'logs each message' do
        allow($diakonos).to receive(:log)

        session.process_queue

        expect($diakonos)
        .to have_received(:log)
        .with(/publishDiagnostics/)
        .ordered
        expect($diakonos)
        .to have_received(:log)
        .with(/logMessage/)
        .ordered
      end
    end

    context 'when the queue is empty' do
      it 'returns without blocking' do
        allow($diakonos).to receive(:log)

        session.process_queue

        expect($diakonos).to have_received(:log).exactly(0).times
      end
    end
  end

  describe '#stop' do
    it 'delegates to the server' do
      allow(server).to receive(:stop)

      session.stop

      expect(server).to have_received(:stop)
    end
  end
end
