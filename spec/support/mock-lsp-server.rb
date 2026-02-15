#!/usr/bin/env ruby
# A minimal LSP server for testing. Speaks JSON-RPC over stdio.
# Responds to: initialize, initialized, shutdown, exit.

require 'json'

$stdin.binmode
$stdout.binmode

HOVER_PROVIDER_CAPABILITY = true

def read_message
  header = $stdin.gets("\r\n\r\n")
  if header
    content_length = header[/Content-Length: (\d+)/i, 1].to_i
    body = $stdin.read(content_length)

    JSON.parse(body, symbolize_names: true)
  end
end

def write_message(message)
  body = JSON.generate(message.merge(jsonrpc: '2.0'))
  $stdout.print "Content-Length: #{body.bytesize}\r\n\r\n#{body}"
  $stdout.flush
end

loop do
  message = read_message
  break if message.nil?

  case message[:method]
  when 'initialize'
    write_message(
      id: message[:id],
      result: {
        capabilities: {
          hoverProvider: HOVER_PROVIDER_CAPABILITY,
          textDocumentSync: 1,
        },
      },
    )
  when 'initialized'
    # Notification; no response needed.
  when 'shutdown'
    write_message(
      id: message[:id],
      result: nil,
    )
  when 'exit'
    break
  end
end
