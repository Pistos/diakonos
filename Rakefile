require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new( :docs ) do |t|
  end
rescue LoadError
  desc "Generate source code documentation with YARD"
  task :docs do
    $stderr.puts "('gem install yard' in order to be able to generate Diakonos source code documentation.)"
  end
end

desc "Clean directory of gems and tarballs"
task :clean do
  system 'rm diakonos-*.*.*.tar.*'
  system 'rm diakonos-*.*.*.gem'
end
