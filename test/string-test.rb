#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_String < Test::Unit::TestCase
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
        s = "x"
        assert_equal( 0, s.indentation_level( 4, true ) )
        assert_equal( 0, s.indentation_level( 4, false ) )
        s = "  x"
        assert_equal( 1, s.indentation_level( 4, true ) )
        assert_equal( 0, s.indentation_level( 4, false ) )
        s = "    x"
        assert_equal( 1, s.indentation_level( 4, true ) )
        assert_equal( 1, s.indentation_level( 4, false ) )
        s = "      x"
        assert_equal( 2, s.indentation_level( 4, true ) )
        assert_equal( 1, s.indentation_level( 4, false ) )
        s = "        x"
        assert_equal( 2, s.indentation_level( 4, true ) )
        assert_equal( 2, s.indentation_level( 4, false ) )
        s = "\tx"
        assert_equal( 2, s.indentation_level( 4, true, 8 ) )
        assert_equal( 2, s.indentation_level( 4, false, 8 ) )
        s = "\t\tx"
        assert_equal( 4, s.indentation_level( 4, true, 8 ) )
        assert_equal( 4, s.indentation_level( 4, false, 8 ) )
        s = "\t  x"
        assert_equal( 3, s.indentation_level( 4, true, 8 ) )
        assert_equal( 2, s.indentation_level( 4, false, 8 ) )
        s = "\t    x"
        assert_equal( 3, s.indentation_level( 4, true, 8 ) )
        assert_equal( 3, s.indentation_level( 4, false, 8 ) )
        s = "\t  \tx"
        assert_equal( 4, s.indentation_level( 4, true, 8 ) )
        assert_equal( 4, s.indentation_level( 4, false, 8 ) )
        s = "\t  \t  x"
        assert_equal( 5, s.indentation_level( 4, true, 8 ) )
        assert_equal( 4, s.indentation_level( 4, false, 8 ) )
        s = "\t  \t   x"
        assert_equal( 5, s.indentation_level( 4, true, 8 ) )
        assert_equal( 4, s.indentation_level( 4, false, 8 ) )
        s = "\t  \t    x"
        assert_equal( 5, s.indentation_level( 4, true, 8 ) )
        assert_equal( 5, s.indentation_level( 4, false, 8 ) )
    end
    
    def test_expandTabs
        s = "              "
        assert_equal( s, s.expandTabs( 8 ) )
        s = "\t"
        assert_equal( " " * 8, s.expandTabs( 8 ) )
        s = "\t\t"
        assert_equal( " " * 8*2, s.expandTabs( 8 ) )
        s = "\t  \t"
        assert_equal( " " * 8*2, s.expandTabs( 8 ) )
        s = "\t  \t  "
        assert_equal( " " * (8*2 + 2), s.expandTabs( 8 ) )
        s = "\t        \t"
        assert_equal( " " * 8*3, s.expandTabs( 8 ) )
        s = "\t         \t"
        assert_equal( " " * 8*3, s.expandTabs( 8 ) )
    end
end