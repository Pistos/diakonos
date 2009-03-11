require 'spec/preparation'

describe 'A String' do
  it 'can substitute the user\'s home directory' do
    "/test".subHome.should.equal "/test"
    "~/test".subHome.should.equal "#{ENV[ 'HOME' ]}/test"
    "/this/is/~/test".subHome.should.equal "/this/is/#{ENV[ 'HOME' ]}/test"
    "~".subHome.should.equal ENV[ 'HOME' ]
  end

  it 'can be interpreted as and converted to a boolean' do
    "true".to_b.should.be.true
    "True".to_b.should.be.true
    "TRUE".to_b.should.be.true
    "tRue".to_b.should.be.true
    "t".to_b.should.be.true
    "T".to_b.should.be.true
    "1".to_b.should.be.true
    "yes".to_b.should.be.true
    "Yes".to_b.should.be.true
    "YES".to_b.should.be.true
    "yEs".to_b.should.be.true
    "y".to_b.should.be.true
    "Y".to_b.should.be.true
    "on".to_b.should.be.true
    "On".to_b.should.be.true
    "ON".to_b.should.be.true
    "oN".to_b.should.be.true
    "+".to_b.should.be.true

    "false".to_b.should.be.false
    "False".to_b.should.be.false
    "FALSE".to_b.should.be.false
    "fALse".to_b.should.be.false
    "f".to_b.should.be.false
    "F".to_b.should.be.false
    "n".to_b.should.be.false
    "N".to_b.should.be.false
    "x".to_b.should.be.false
    "X".to_b.should.be.false
    "0".to_b.should.be.false
    "2".to_b.should.be.false
    "no".to_b.should.be.false
    "No".to_b.should.be.false
    "NO".to_b.should.be.false
    "nO".to_b.should.be.false
    "off".to_b.should.be.false
    "Off".to_b.should.be.false
    "OFF".to_b.should.be.false
    "oFf".to_b.should.be.false
    "-".to_b.should.be.false
    "*".to_b.should.be.false
    "foobar".to_b.should.be.false
  end

  it 'knows its own indentation level' do
    s = "x"
    s.indentation_level( 4, true ).should.equal 0
    s.indentation_level( 4, false ).should.equal 0
    s = "  x"
    s.indentation_level( 4, true ).should.equal 1
    s.indentation_level( 4, false ).should.equal 0
    s = "    x"
    s.indentation_level( 4, true ).should.equal 1
    s.indentation_level( 4, false ).should.equal 1
    s = "      x"
    s.indentation_level( 4, true ).should.equal 2
    s.indentation_level( 4, false ).should.equal 1
    s = "        x"
    s.indentation_level( 4, true ).should.equal 2
    s.indentation_level( 4, false ).should.equal 2
    s = "\tx"
    s.indentation_level( 4, true, 8 ).should.equal 2
    s.indentation_level( 4, false, 8 ).should.equal 2
    s = "\t\tx"
    s.indentation_level( 4, true, 8 ).should.equal 4
    s.indentation_level( 4, false, 8 ).should.equal 4
    s = "\t  x"
    s.indentation_level( 4, true, 8 ).should.equal 3
    s.indentation_level( 4, false, 8 ).should.equal 2
    s = "\t    x"
    s.indentation_level( 4, true, 8 ).should.equal 3
    s.indentation_level( 4, false, 8 ).should.equal 3
    s = "\t  \tx"
    s.indentation_level( 4, true, 8 ).should.equal 4
    s.indentation_level( 4, false, 8 ).should.equal 4
    s = "\t  \t  x"
    s.indentation_level( 4, true, 8 ).should.equal 5
    s.indentation_level( 4, false, 8 ).should.equal 4
    s = "\t  \t   x"
    s.indentation_level( 4, true, 8 ).should.equal 5
    s.indentation_level( 4, false, 8 ).should.equal 4
    s = "\t  \t    x"
    s.indentation_level( 4, true, 8 ).should.equal 5
    s.indentation_level( 4, false, 8 ).should.equal 5
  end

  it 'can expand its tabs' do
    s = "              "
    s.expandTabs( 8 ).should.equal s
    s = "\t"
    s.expandTabs( 8 ).should.equal " " * 8
    s = "\t\t"
    s.expandTabs( 8 ).should.equal " " * 8*2
    s = "\t  \t"
    s.expandTabs( 8 ).should.equal " " * 8*2
    s = "\t  \t  "
    s.expandTabs( 8 ).should.equal " " * (8*2 + 2)
    s = "\t        \t"
    s.expandTabs( 8 ).should.equal " " * 8*3
    s = "\t         \t"
    s.expandTabs( 8 ).should.equal " " * 8*3
  end

  it 'knows the index of a first matching regexp group' do
    s = "abc def ghi"
    s.group_index( /abc/ ).should.equal [ 0, "abc" ]
    s.group_index( /def/ ).should.equal [ 4, "def" ]
    s.group_index( /a(b)c/ ).should.equal [ 1, "b" ]
    s.group_index( /a(b)c d(e)f/ ).should.equal [ 1, "b" ]
    s.group_index( /q/ ).should.equal [ nil, nil ]
    s.group_index( /abc(q?)/ ).should.equal [ 3, '' ]
  end
end