require 'spec/preparation'

describe 'A Regexp' do
  it 'knows if beginning-of-string is used' do
    /^test/.uses_bos.should.be.true
    /test/.uses_bos.should.be.false
    /t^est/.uses_bos.should.be.false
  end
end