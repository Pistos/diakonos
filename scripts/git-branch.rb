git_proc = Proc.new do |buffer|
  if buffer and buffer.name
    dir = File.dirname( File.expand_path( buffer.name ) )
  else
    dir = '.'
  end

  if File.exist? dir
    branch = Dir.chdir( dir ){ `git symbolic-ref HEAD 2>/dev/null`[ /[^\/\n]+$/ ] }
    $diakonos.set_status_variable(
      '@git_branch',
      branch ? " git:#{branch} " : nil
    )
  end
end

$diakonos.register_proc( git_proc, :after_open )
$diakonos.register_proc( git_proc, :after_buffer_switch )
