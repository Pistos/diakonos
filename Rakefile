require 'rake'
require 'rake/testtask'
require 'yard'

task :default => [ :test ]
task :spec => [ :test ]

desc "Run Diakonos tests"
task :test do
  system 'bacon -Ilib spec/*.rb'
end

desc "Generate source code documentation with YARD"
YARD::Rake::YardocTask.new( :docs ) do |t|
end