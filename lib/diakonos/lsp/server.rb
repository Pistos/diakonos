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
        @stopping = false
        @transport = nil
        @working_directory = working_directory
        @write_queue = Thread::Queue.new
        @writer_thread = nil

        spawn_process
        handshake
        start_reader_thread
        start_writer_thread
      end

      def stop
        @stopping = true
        @write_queue.push(nil)
        @writer_thread&.join
        @reader_thread&.kill
        @reader_thread&.join
        if alive?
          shut_down
        end
      end

      def write(message:)
        @write_queue.push(message)
      end

      private def alive?
        if @pid
          Process
          .waitpid(@pid, Process::WNOHANG)
          .nil?
        end
      end

      private def handshake
        request_id = next_request_id
        @transport.write(
          message: {
            id: request_id,
            method: 'initialize',
            params: {
              capabilities: {
                textDocument: {
                  definition: {
                    dynamicRegistration: false,
                  },
                  hover: {
                    dynamicRegistration: false,
                  },
                  publishDiagnostics: {
                    relatedInformation: true,
                  },
                },
              },
              processId: Process.pid,
              rootUri: "#{FILE_URI_PREFIX}#{@working_directory}",
            },
          },
        )

        response = nil
        loop do
          message = @transport.read_one
          if message.nil?
            Process.waitpid(@pid)
            stderr_output = @stderr_io.read.strip
            @pid = nil

            raise "LSP server failed to start: #{stderr_output}"
          end
          if message[:id] == request_id
            response = message
            break
          end
          @queue.push(message)
        end
        @capabilities = response[:result][:capabilities]

        @transport.write(
          message: {
            method: 'initialized',
            params: {},
          },
        )
      end

      def next_request_id
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

      private def start_writer_thread
        @writer_thread = Thread.new do
          loop do
            message = @write_queue.pop
            if message.nil?
              break
            end

            @transport.write(message:)
          end
        rescue => e
          $diakonos.log("LSP writer thread error: #{e.class}: #{e.message}")
        end
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
          if ! (e.is_a?(IOError) && @stopping)
            $diakonos.log("LSP reader thread error: #{e.class}: #{e.message}")
          end
        end
      end
    end
  end
end
