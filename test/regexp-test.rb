#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_Regexp < Test::Unit::TestCase
    def test_usesBOS
        r = /^test/
        assert_equal(
            true, r.usesBOS,
            "/#{r.source}/.usesBOS should be true"
        )
        r = /test/
        assert_equal(
            false, r.usesBOS,
            "/#{r.source}/.usesBOS should be false"
        )
    end
end