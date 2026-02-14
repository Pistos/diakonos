require 'spec_helper'

RSpec.describe Diakonos::Lsp::Transport do
  READ_BUFFER_SIZE = 4096

  let(:server_read) { ios[0] }
  let(:client_write) { ios[1] }
  let(:client_read) { ios[2] }
  let(:server_write) { ios[3] }
  let(:ios) {
    sr, cw = IO.pipe
    cr, sw = IO.pipe

    [sr, cw, cr, sw]
  }
  let(:transport) {
    described_class.new(
      reader_io: client_read,
      writer_io: client_write,
    )
  }

  after do
    [client_read, client_write, server_read, server_write].each do |io|
      if ! io.closed?
        io.close
      end
    end
  end

  describe '#write' do
    it 'frames a message with Content-Length header and JSON-RPC envelope' do
      transport.send(:write, message: { method: 'initialize', id: 1 })

      raw = server_read.readpartial(READ_BUFFER_SIZE)
      header, body = raw.split("\r\n\r\n", 2)
      parsed = JSON.parse(body)

      expect(header).to match(/Content-Length: \d+/)
      expect(parsed['jsonrpc']).to eq '2.0'
      expect(parsed['id']).to eq 1
      expect(parsed['method']).to eq 'initialize'
    end
  end

  describe '#read' do
    context 'with a single message' do
      before do
        body = JSON.generate(
          jsonrpc: '2.0',
          method: 'textDocument/publishDiagnostics',
          params: { uri: 'file:///test.rb' },
        )
        server_write.print "Content-Length: #{body.bytesize}\r\n\r\n#{body}"
        server_write.close
      end

      it 'parses the framed JSON-RPC message and yields it' do
        received = []
        transport.send(:read) { |msg| received << msg }

        expect(received.length).to eq 1
        expect(received[0][:method]).to eq 'textDocument/publishDiagnostics'
        expect(received[0][:params][:uri]).to eq 'file:///test.rb'
      end
    end

    context 'with multiple messages in sequence' do
      before do
        messages = [
          { jsonrpc: '2.0', id: 1, result: { capabilities: {} } },
          {
            jsonrpc: '2.0',
            method: 'window/logMessage',
            params: { type: 3, message: 'hello' },
          },
        ]
        messages.each do |msg|
          body = JSON.generate(msg)
          server_write.print "Content-Length: #{body.bytesize}\r\n\r\n#{body}"
        end
        server_write.close
      end

      it 'yields each message' do
        received = []
        transport.send(:read) { |msg| received << msg }

        expect(received.length).to eq 2
        expect(received[0][:id]).to eq 1
        expect(received[1][:method]).to eq 'window/logMessage'
      end
    end
  end

  describe '#close' do
    it 'closes both reader and writer IOs' do
      transport.send(:close)

      expect(client_read.closed?).to eq true
      expect(client_write.closed?).to eq true
    end
  end
end
