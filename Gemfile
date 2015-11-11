source 'https://rubygems.org'

# For Ruby 2.2, because :ruby_22 is not a recognize platform with older Bundler versions
gem 'curses'  if RUBY_VERSION >= '2.1'

# For Ruby 2.1, and so that it is avoided for Ruby 2.0
gem 'curses', :platforms => [:ruby_21]

group :test do
  gem 'rake'
  gem 'rspec'
end
