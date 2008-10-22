# This is a trivial example of how to hook Ruby code onto a Diakonos event.
# Create a Proc object, then register it with $diakonos.registerProc.

example_proc = Proc.new do |buffer|
    filename = buffer.name
    $diakonos.cursorBOF
end

$diakonos.registerProc( example_proc, :after_save )