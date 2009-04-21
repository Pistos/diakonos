require 'spec/preparation'

describe 'Diakonos' do

  before do
    @d = $diakonos
    @b = @d.open_file( SAMPLE_FILE )
  end

  after do
    @d.close_file @b, Diakonos::CHOICE_NO_TO_ALL
  end


end