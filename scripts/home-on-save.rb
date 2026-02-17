# This is a trivial example of how to hook Ruby code onto a Diakonos event.
# Create a Proc object, then register it with $diakonos.register_proc.

example_proc = proc { |buffer|
  $diakonos.log "Buffer name: #{buffer.name}"
  $diakonos.cursorBOF
}

$diakonos.register_proc( example_proc, :after_save )
