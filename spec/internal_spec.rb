require 'spec_helper'

RSpec.describe '::Diakonos can' do

  it 'parse a filename and line number from a String' do
    expect(::Diakonos.parse_filename_and_line_number('abc.rb')).to eq ['abc.rb', nil]
    expect(::Diakonos.parse_filename_and_line_number('/absolute/path/abc.rb')).to eq ['/absolute/path/abc.rb', nil]
    expect(::Diakonos.parse_filename_and_line_number('abc.rb:1')).to eq ['abc.rb', 0]
    expect(::Diakonos.parse_filename_and_line_number('abc.rb:5')).to eq ['abc.rb', 4]
    expect(::Diakonos.parse_filename_and_line_number('abc.rb:10')).to eq ['abc.rb', 9]
    expect(::Diakonos.parse_filename_and_line_number('/absolute/path/abc.rb:15')).to eq ['/absolute/path/abc.rb', 14]
    expect(::Diakonos.parse_filename_and_line_number('relative/path/abc.rb:15')).to eq ['relative/path/abc.rb', 14]
  end

end
