require 'rake'
require 'rake/testtask'

task :default => [ :test ]

desc "Run Diakonos tests"

Rake::TestTask.new( "test" ) do |t|
  t.pattern = 'test/*-test.rb'
  t.verbose = true
  t.warning = true
end

