require 'spec_helper'

RSpec.describe 'A Regexp' do
  it 'knows if beginning-of-string is used' do
    expect(/^test/.uses_bos).to eq true
    expect(/test/.uses_bos).to eq false
    expect(/t^est/.uses_bos).to eq false
  end
end
