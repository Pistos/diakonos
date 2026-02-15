require 'thread'

require 'diakonos/lsp/transport'

module Diakonos
  module Lsp
    class Server
      attr_reader :capabilities, :queue

      def initialize(command:, working_directory:)
        @capabilities = nil
        @command = command
        @pid = nil
        @queue = Thread::Queue.new
        @reader_thread = nil
        @request_id = 0
        @stderr_io = nil
        @transport = nil
        @working_directory = working_directory

        spawn_process
        handshake
        start_reader_thread
      end

      def stop
        if alive?
          shut_down
        end
        if @reader_thread
          @reader_thread.join
        end
      end

      def write(message:)
        @transport.write(message:)
      end

      private def alive?
        if @pid
          Process
          .waitpid(@pid, Process::WNOHANG)
          .nil?
        end
      end

      private def handshake
        @transport.write(
          message: {
            id: next_request_id,
            method: 'initialize',
            params: {
              capabilities: {},
              processId: Process.pid,
              rootUri: "file://#{@working_directory}",
            },
          },
        )

        response = @transport.read_one
        if response.nil?
          Process.waitpid(@pid)
          stderr_output = @stderr_io.read.strip
          @pid = nil

          raise "LSP server failed to start: #{stderr_output}"
        end
        @capabilities = response[:result][:capabilities]

        @transport.write(
          message: {
            method: 'initialized',
            params: {},
          },
        )
      end

      private def next_request_id
        @request_id += 1
      end

      private def shut_down
        @transport.write(
          message: {
            id: next_request_id,
            method: 'shutdown',
          },
        )
        @transport.read_one
        @transport.write(
          message: {
            method: 'exit',
          },
        )
        @transport.close
        @stderr_io.close
        Process.waitpid(@pid)
        @pid = nil
      end

      private def spawn_process
        child_stdin_read, child_stdin_write = IO.pipe
        child_stdout_read, child_stdout_write = IO.pipe
        child_stderr_read, child_stderr_write = IO.pipe
        shell = ENV['SHELL'] || '/bin/sh'

        @pid = Process.spawn(
          shell, '-lc', @command,
          chdir: @working_directory,
          err: child_stderr_write,
          in: child_stdin_read,
          out: child_stdout_write,
        )

        child_stdin_read.close
        child_stdout_write.close
        child_stderr_write.close

        @stderr_io = child_stderr_read
        @transport = Transport.new(
          reader_io: child_stdout_read,
          writer_io: child_stdin_write,
        )
      end

      private def start_reader_thread
        @reader_thread = Thread.new do
          loop do
            message = @transport.read_one
            if message.nil?
              break
            end
            @queue.push(message)
          end
        rescue => e
          $diakonos.log("LSP reader thread error: #{e.class}: #{e.message}")
        end
      end
    end
  end
end
