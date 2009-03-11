#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_Diakonos < Test::Unit::TestCase
    def setup
      @diakonos = Diakonos::Diakonos.new [ '--test', ]
    end

    def teardown
      @diakonos.quit
    end

    def test_true
      assert true
    end
end