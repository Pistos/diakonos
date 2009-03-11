require 'rake'
require 'rake/testtask'

task :default => [ :test ]

desc "Run Diakonos tests"
task :test do
  system 'bacon -Ilib spec/*.rb'
end

