#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_String < Test::Unit::TestCase
    def test_subHome
        s = "/test"
        assert_equal(
            "/test", s.subHome,
            "Original string: '#{s}'"
        )
        s = "~/test"
        assert_equal(
            "#{ENV[ 'HOME' ]}/test", s.subHome,
            "Original string: '#{s}'"
        )
        s = "/this/is/~/test"
        assert_equal(
            "/this/is/#{ENV[ 'HOME' ]}/test", s.subHome,
            "Original string: '#{s}'"
        )
        s = "~"
        assert_equal(
            ENV[ 'HOME' ], s.subHome,
            "Original string: '#{s}'"
        )
    end
end