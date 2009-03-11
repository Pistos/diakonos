#!/usr/bin/env ruby

# This is only a sample file used in the tests.

class Sample
  def initialize
    @x = 1
    @y = 2
  end

  def printout
    puts x
    puts y
  end
end

s = Sample.new
s.printout
