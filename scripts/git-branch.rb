git_proc = Proc.new do |buffer|
  if buffer and buffer.name
    dir = File.dirname( File.expand_path( buffer.name ) )
  else
    dir = '.'
  end
  
  git_dir = nil
  loop do
    old_dir = dir
    if File.exist? "#{dir}/.git"
      git_dir = "#{dir}/.git"
      break
    end

    dir = File.dirname( dir )
    if dir == old_dir
      break
    end
  end
  
  if git_dir
    $diakonos.set_status_variable(
      '@git_branch',
      ' git:' + `git --git-dir=#{git_dir} symbolic-ref HEAD 2>/dev/null | cut -d '/' -f 3`.strip + ' '
    )
  else
    $diakonos.set_status_variable(
      '@git_branch',
      nil
    )
  end
  
end

$diakonos.register_proc( git_proc, :after_open )
$diakonos.register_proc( git_proc, :after_buffer_switch )
