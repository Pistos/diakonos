require 'spec_helper'

RSpec.describe '#check_syntax' do
  let(:d) { $diakonos }
  let(:buffer) { d.open_file(SAMPLE_FILE) }
  let(:settings) { d.instance_variable_get(:@settings) }

  before do
    buffer
    allow(d).to receive(:set_iline)
    allow(d).to receive(:shell)
  end

  after do
    d.close_buffer buffer, to_all: Diakonos::CHOICE_NO_TO_ALL
  end

  context 'when the buffer has a known language' do
    before do
      buffer.set_language('ruby')
    end

    context 'when check_syntax is not configured for the language' do
      before do
        settings.delete('lang.ruby.check_syntax')
      end

      it 'shows a "not configured" message on the interaction line' do
        d.check_syntax

        expect(d)
        .to have_received(:set_iline)
        .with('No syntax check command configured for: ruby')
      end
    end

    context 'when check_syntax is configured for the language' do
      before do
        settings['lang.ruby.check_syntax'] = 'ruby -c $f'
      end

      it 'delegates to shell with the configured command' do
        d.check_syntax

        expect(d)
        .to have_received(:shell)
        .with('ruby -c $f')
      end
    end
  end
end
