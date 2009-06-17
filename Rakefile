require 'rake'
require 'rake/testtask'

task :default => [ :test ]
task :spec => [ :test ]

desc "Run Diakonos tests"
task :test do
  system 'bacon -Ilib spec/*.rb spec/*/*.rb'
end

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