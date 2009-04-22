#!/usr/bin/env ruby

# This is only a sample file used in the tests.

class Sample
  attr_reader :x, :y

  def initialize
    @x = 1
    @y = 2
  end

  def inspection
    x.inspect
    y.inspect
  end
end

s = Sample.new
s.inspection

[
  :just => :a,
  :test => :array,
]
