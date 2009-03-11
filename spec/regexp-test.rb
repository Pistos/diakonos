#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_Regexp < Test::Unit::TestCase
    def test_uses_bos
        r = /^test/
        assert_equal(
            true, r.uses_bos,
            "/#{r.source}/.uses_bos should be true"
        )
        
        r = /test/
        assert_equal(
            false, r.uses_bos,
            "/#{r.source}/.uses_bos should be false"
        )
        
        r = /t^est/
        assert_equal(
            false, r.uses_bos,
            "/#{r.source}/.uses_bos should be false"
        )
    end
end