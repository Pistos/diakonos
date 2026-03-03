require 'spec_helper'

RSpec.describe 'Status line' do
  include_context 'virtual screen'

  let!(:buffer) { $diakonos.open_file(SAMPLE_FILE) }

  after do
    $diakonos.close_buffer buffer, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'renders the filename' do
    $diakonos.update_status_line
    status = $diakonos.win_status.virtual_screen

    expect(status[0]).to include('sample-file.rb')
  end

  it 'renders the file type' do
    $diakonos.update_status_line
    status = $diakonos.win_status.virtual_screen

    expect(status[0]).to include('(ruby)')
  end

  it 'renders the cursor position' do
    buffer.cursor_to(0, 0)
    $diakonos.update_status_line
    status = $diakonos.win_status.virtual_screen

    expect(status[0]).to include('L  1/')
    expect(status[0]).to include('C 1')
  end

  it 'renders the buffer count' do
    $diakonos.update_status_line
    status = $diakonos.win_status.virtual_screen

    expect(status[0]).to match(/Buf \d+ of \d+/)
  end
end
