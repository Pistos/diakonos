#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_String < Test::Unit::TestCase
    def setup
        $diakonos = Diakonos.new
    end
    
    def test_subHome
        s = "/test"
        assert_equal(
            "/test",
            s.subHome,
            "Original string: '#{s}'"
        )
        s = "~/test"
        assert_equal(
            "#{ENV[ 'HOME' ]}/test",
            s.subHome,
            "Original string: '#{s}'"
        )
        s = "/this/is/~/test"
        assert_equal(
            "/this/is/#{ENV[ 'HOME' ]}/test",
            s.subHome,
            "Original string: '#{s}'"
        )
        s = "~"
        assert_equal(
            ENV[ 'HOME' ],
            s.subHome,
            "Original string: '#{s}'"
        )
    end
    
    def test_indentation_level
        #indentation_level( indent_size, indent_roundup, indent_ignore_charset = nil )
        s = "x"
        assert_equal( 0, s.indentation_level( 4, true ) )
        assert_equal( 0, s.indentation_level( 4, false ) )
        s = "  x"
        assert_equal( 1, s.indentation_level( 4, true ) )
        assert_equal( 0, s.indentation_level( 4, false ) )
    end
end