require 'spec_helper'

RSpec.describe Diakonos::Lsp::Diagnostic do
  let(:data) {
    {
      message: 'Undefined method `foo`',
      range: {
        end: { character: 10, line: 4 },
        start: { character: 0, line: 4 },
      },
      severity:,
    }
  }
  let(:diagnostic) { described_class.new(data:) }
  let(:severity) { 1 }

  describe '#to_s' do
    context 'with an error severity' do
      let(:severity) { 1 }

      it 'formats with the Error label and 1-indexed line number' do
        expect(diagnostic.to_s).to eq "L5: Error: Undefined method `foo`"
      end
    end

    context 'with a warning severity' do
      let(:severity) { 2 }

      it 'formats with the Warning label' do
        expect(diagnostic.to_s).to eq "L5: Warning: Undefined method `foo`"
      end
    end

    context 'with an info severity' do
      let(:severity) { 3 }

      it 'formats with the Info label' do
        expect(diagnostic.to_s).to eq "L5: Info: Undefined method `foo`"
      end
    end

    context 'with a hint severity' do
      let(:severity) { 4 }

      it 'formats with the Hint label' do
        expect(diagnostic.to_s).to eq "L5: Hint: Undefined method `foo`"
      end
    end

    context 'with an unknown severity' do
      let(:severity) { 99 }

      it 'formats with a generic Diagnostic label' do
        expect(diagnostic.to_s).to eq "L5: Diagnostic: Undefined method `foo`"
      end
    end

    context 'with no severity' do
      let(:severity) { nil }

      it 'formats with a generic Diagnostic label' do
        expect(diagnostic.to_s).to eq "L5: Diagnostic: Undefined method `foo`"
      end
    end
  end

  describe '#start_line' do
    it 'returns the zero-indexed start line' do
      expect(diagnostic.start_line).to eq 4
    end
  end

  describe '#end_line' do
    it 'returns the zero-indexed end line' do
      expect(diagnostic.end_line).to eq 4
    end
  end

  describe '#message' do
    it 'returns the diagnostic message' do
      expect(diagnostic.message).to eq 'Undefined method `foo`'
    end
  end
end
