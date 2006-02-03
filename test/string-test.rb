#!/usr/bin/env ruby

require 'test/unit'
require 'diakonos'

class TC_String < Test::Unit::TestCase
    def test_subHome
        s = "/test"
        assert_equal(
            "/test",
            s.subHome
        )
        s = "~/test"
        assert_equal(
            "#{ENV[ 'HOME' ]}/test",
            s.subHome
        )
        s = "/this/is/~/test"
        assert_equal(
            "/this/is/#{ENV[ 'HOME' ]}/test",
            s.subHome
        )
        s = "~"
        assert_equal(
            ENV[ 'HOME' ],
            s.subHome
        )
    end
    
    def test_to_b
        assert( "true".to_b )
        assert( "True".to_b )
        assert( "TRUE".to_b )
        assert( "tRue".to_b )
        assert( "t".to_b )
        assert( "T".to_b )
        assert( "1".to_b )
        assert( "yes".to_b )
        assert( "Yes".to_b )
        assert( "YES".to_b )
        assert( "yEs".to_b )
        assert( "y".to_b )
        assert( "Y".to_b )
        assert( "on".to_b )
        assert( "On".to_b )
        assert( "ON".to_b )
        assert( "oN".to_b )
        assert( "+".to_b )
        assert_equal( false, "false".to_b )
        assert_equal( false, "False".to_b )
        assert_equal( false, "FALSE".to_b )
        assert_equal( false, "fALse".to_b )
        assert_equal( false, "f".to_b )
        assert_equal( false, "F".to_b )
        assert_equal( false, "n".to_b )
        assert_equal( false, "N".to_b )
        assert_equal( false, "x".to_b )
        assert_equal( false, "X".to_b )
        assert_equal( false, "0".to_b )
        assert_equal( false, "2".to_b )
        assert_equal( false, "no".to_b )
        assert_equal( false, "No".to_b )
        assert_equal( false, "NO".to_b )
        assert_equal( false, "nO".to_b )
        assert_equal( false, "off".to_b )
        assert_equal( false, "Off".to_b )
        assert_equal( false, "OFF".to_b )
        assert_equal( false, "oFf".to_b )
        assert_equal( false, "-".to_b )
        assert_equal( false, "*".to_b )
        assert_equal( false, "foobar".to_b )
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