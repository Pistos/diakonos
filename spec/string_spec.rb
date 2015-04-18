require 'spec_helper'

RSpec.describe 'A String' do
  it 'can be interpreted as and converted to a boolean' do
    expect("true".to_b).to eq true
    expect("True".to_b).to eq true
    expect("TRUE".to_b).to eq true
    expect("tRue".to_b).to eq true
    expect("t".to_b).to eq true
    expect("T".to_b).to eq true
    expect("1".to_b).to eq true
    expect("yes".to_b).to eq true
    expect("Yes".to_b).to eq true
    expect("YES".to_b).to eq true
    expect("yEs".to_b).to eq true
    expect("y".to_b).to eq true
    expect("Y".to_b).to eq true
    expect("on".to_b).to eq true
    expect("On".to_b).to eq true
    expect("ON".to_b).to eq true
    expect("oN".to_b).to eq true
    expect("+".to_b).to eq true

    expect("false".to_b).to eq false
    expect("False".to_b).to eq false
    expect("FALSE".to_b).to eq false
    expect("fALse".to_b).to eq false
    expect("f".to_b).to eq false
    expect("F".to_b).to eq false
    expect("n".to_b).to eq false
    expect("N".to_b).to eq false
    expect("x".to_b).to eq false
    expect("X".to_b).to eq false
    expect("0".to_b).to eq false
    expect("2".to_b).to eq false
    expect("no".to_b).to eq false
    expect("No".to_b).to eq false
    expect("NO".to_b).to eq false
    expect("nO".to_b).to eq false
    expect("off".to_b).to eq false
    expect("Off".to_b).to eq false
    expect("OFF".to_b).to eq false
    expect("oFf".to_b).to eq false
    expect("-".to_b).to eq false
    expect("*".to_b).to eq false
    expect("foobar".to_b).to eq false
  end

  it 'can expand its tabs' do
    s = "              "
    expect(s.expand_tabs(8)).to eq(s)
    s = "\t"
    expect(s.expand_tabs(8)).to eq(" " * 8)
    s = "\t\t"
    expect(s.expand_tabs(8)).to eq(" " * 8*2)
    s = "\t  \t"
    expect(s.expand_tabs(8)).to eq(" " * 8*2)
    s = "\t  \t  "
    expect(s.expand_tabs(8)).to eq(" " * (8*2 + 2))
    s = "\t        \t"
    expect(s.expand_tabs(8)).to eq(" " * 8*3)
    s = "\t         \t"
    expect(s.expand_tabs(8)).to eq(" " * 8*3)
  end

  it 'knows the index of a first matching regexp group' do
    s = "abc def ghi"
    expect(s.group_index( /abc/ )).to eq([ 0, "abc" ])
    expect(s.group_index( /def/ )).to eq([ 4, "def" ])
    expect(s.group_index( /a(b)c/ )).to eq([ 1, "b" ])
    expect(s.group_index( /a(b)c d(e)f/ )).to eq([ 1, "b" ])
    expect(s.group_index( /q/ )).to eq([ nil, nil ])
    expect(s.group_index( /abc(q?)/ )).to eq([ 3, '' ])
  end
end
