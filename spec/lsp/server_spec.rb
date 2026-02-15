require 'spec_helper'

RSpec.describe Diakonos::Lsp::Server do
  let(:mock_server_path) {
    File.expand_path('../support/mock-lsp-server.rb', __dir__)
  }
  let(:command) { "ruby #{mock_server_path}" }
  let(:working_directory) { Dir.pwd }

  around do |example|
    Bundler.with_unbundled_env { example.run }
  end

  describe '#initialize' do
    let(:server) {
      described_class.new(
        command:,
        working_directory:,
      )
    }

    after do
      server.stop
    end

    it 'completes the handshake and stores capabilities' do
      expect(server.capabilities).to include(
        hoverProvider: true,
        textDocumentSync: 1,
      )
    end
  end

  describe '#stop' do
    let(:server) {
      described_class.new(
        command:,
        working_directory:,
      )
    }

    it 'shuts down and reaps the process' do
      pid = server.instance_variable_get(:@pid)
      server.stop

      expect {
        Process.waitpid(pid, Process::WNOHANG)
      }.to raise_error(Errno::ECHILD)
    end
  end

  describe 'with a nonexistent command' do
    it 'raises with a descriptive message' do
      expect {
        described_class.new(
          command: 'nonexistent-lsp-server-binary-xyz',
          working_directory:,
        )
      }.to raise_error(RuntimeError, /LSP server failed to start/)
    end
  end

  describe 'with a nonexistent working directory' do
    it 'raises Errno::ENOENT' do
      expect {
        described_class.new(
          command:,
          working_directory: '/nonexistent/directory',
        )
      }.to raise_error(Errno::ENOENT)
    end
  end
end
