require 'spec_helper'

RSpec.describe 'Virtual screen' do
  include_context 'virtual screen'

  before do
    @b = $diakonos.open_file(SAMPLE_FILE)
  end

  after do
    $diakonos.close_buffer @b, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  it 'captures buffer content rendered to win_main' do
    @b.display

    screen = $diakonos.win_main.virtual_screen
    expect(screen).not_to be_nil
    expect(screen[0]).to include('#!/usr/bin/env ruby')
  end

  it 'captures multiple lines of buffer content' do
    @b.display

    screen = $diakonos.win_main.virtual_screen
    expect(screen[2]).to include('# This is only a sample file used in the tests.')
    expect(screen[4]).to include('class Sample')
  end

  it 'returns nil when framebuffer was never initialised' do
    $use_virtual_screen = false
    fresh_window = Diakonos::Window.new(10, 40, 0, 0)
    fresh_window.close

    expect(fresh_window.virtual_screen).to be_nil
  end

  it 'resets framebuffer to blank spaces' do
    @b.display
    screen_before = $diakonos.win_main.virtual_screen
    expect(screen_before[0]).to include('#!/usr/bin/env ruby')

    $diakonos.win_main.reset_virtual_screen
    screen_after = $diakonos.win_main.virtual_screen

    expect(screen_after[0]).not_to include('#!')
    expect(screen_after[0].strip).to eq('')
  end
end
