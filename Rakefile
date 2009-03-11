require 'rake'
require 'rake/testtask'

task :default => [ :test ]
task :spec => [ :test ]

desc "Run Diakonos tests"
task :test do
  system 'bacon -Ilib spec/*.rb'
end

