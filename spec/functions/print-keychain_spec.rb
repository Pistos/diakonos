require 'spec_helper'

RSpec.describe 'A Diakonos user can use print_keychain (Alt-K) mode' do
  let(:d) { $diakonos }
  let(:b) { d.open_file }
  let(:ctrl_d) { Diakonos::Keying::KEYSTRINGS.index('ctrl+d') }

  describe '#print_keychain' do
    before do
      d.print_keychain
    end

    after do
      d.close_buffer(b, to_all: Diakonos::CHOICE_NO_TO_ALL)
    end

    context 'when the user types a complete keychain then Enter' do
      before do
        $keystrokes = ['t'.ord, Diakonos::ENTER]
      end

      it 'inserts the keychain string into the buffer' do
        expect {
          d.process_keystroke([], 'edit', ctrl_d)
        }.to change { b[0] }
        .from('')
        .to('ctrl+d t')
      end
    end

    context 'when a getch timeout (nil) occurs between the first and second keychain key' do
      before do
        $keystrokes = [nil, 't'.ord, Diakonos::ENTER]
      end

      it 'still completes the keychain and inserts its string into the buffer' do
        expect {
          d.process_keystroke([], 'edit', ctrl_d)
        }.to change { b[0] }
        .from('')
        .to('ctrl+d t')
      end
    end
  end
end
