proc = Proc.new do |buffer|
    filename = buffer.name
    $diakonos.cursorBOF
end

$diakonos.registerProc( proc, :after_save )