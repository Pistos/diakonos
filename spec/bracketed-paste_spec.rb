require 'spec_helper'

RSpec.describe Diakonos::BracketedPaste do
  let(:bp) { described_class.new(testing: true) }
  let(:window) { $diakonos.win_main }

  before do
    allow(Curses)
    .to receive(:ungetch) { |c|
      $keystrokes.unshift(c)
    }
  end

  describe '#try_read' do
    context 'when the start marker suffix follows' do
      before do
        $keystrokes = "[200~hello\e[201~".chars
      end

      it 'returns the pasted text' do
        expect(bp.try_read(mode: 'edit', window:))
        .to eq "hello"
      end
    end

    context 'when the bytes do not match the start marker' do
      before do
        $keystrokes = "[Axyz".chars
      end

      it 'returns nil' do
        expect(bp.try_read(mode: 'edit', window:))
        .to be_nil
      end

      it 'ungetch-es the consumed chars so they remain available' do
        bp.try_read(mode: 'edit', window:)

        expect($keystrokes[0]).to eq "[".ord
        expect($keystrokes[1]).to eq "A".ord
      end
    end

    context 'when input times out mid-detection' do
      before do
        $keystrokes = ["[", "2"]
      end

      it 'returns nil' do
        expect(bp.try_read(mode: 'edit', window:))
        .to be_nil
      end
    end

    context 'with multi-line paste in edit mode' do
      before do
        $keystrokes = "[200~line1\rline2\e[201~".chars
      end

      it 'converts ENTER to newline' do
        expect(bp.try_read(mode: 'edit', window:))
        .to eq "line1\nline2"
      end
    end

    context 'with multi-line paste in input mode' do
      before do
        $keystrokes = "[200~line1\rline2\e[201~".chars
      end

      it 'strips ENTER characters' do
        expect(bp.try_read(mode: 'input', window:))
        .to eq "line1line2"
      end
    end

    context 'when paste contains a non-typeable character (function key attack)' do
      before do
        # Simulate: curses translated \eOQ to KEY_F2 (integer 266) inside paste
        $keystrokes = "[200~".chars + [266] + "evil command\e[201~".chars
      end

      it 'discards the function key and collects the rest as text' do
        expect(bp.try_read(mode: 'edit', window:))
        .to eq "evil command"
      end
    end

    context 'when an injected end marker is followed by more input' do
      before do
        # Attacker injects \e[201~ inside the paste, followed by more content,
        # then the real end marker.
        fake_end = "\e[201~"
        real_end = "\e[201~"
        $keystrokes = "[200~safe#{fake_end}more text#{real_end}".chars
      end

      it 'continues collecting past the fake marker' do
        expect(bp.try_read(mode: 'edit', window:))
        .to eq "safemore text"
      end
    end
  end

  describe '#enable_paste_mode / #disable_paste_mode' do
    context 'in testing mode' do
      it 'does not write to stdout' do
        expect($stdout).not_to receive(:write)

        bp.enable_paste_mode
        bp.disable_paste_mode
      end
    end
  end
end
