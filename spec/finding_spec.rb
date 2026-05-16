require 'spec_helper'

RSpec.describe Diakonos::Finding do
  let(:lines) { ['hello world', 'second line', 'third line'] }
  let(:range) {
    Diakonos::Range.new(
      0, 0,
      0, 5
    )
  }
  let(:regexp_match) { 'hello world'.match(/(\w+) (\w+)/) }
  let(:regexps) { [/hello/] }
  let(:search_area) {
    Diakonos::Range.new(
      0, 0,
      10, 100
    )
  }

  describe '#captured_group' do
    subject(:group) { finding.captured_group(index) }

    context 'given a Finding with a two-group match' do
      let(:finding) { described_class.new(range, regexp_match) }

      context 'when index is 0' do
        let(:index) { 0 }

        it 'returns the full match' do
          expect(group).to eq 'hello world'
        end
      end

      context 'when index is 1' do
        let(:index) { 1 }

        it 'returns the first captured group' do
          expect(group).to eq 'hello'
        end
      end
    end
  end

  describe '.confirm' do
    subject(:finding) {
      described_class.confirm(
        range,
        regexps,
        lines,
        search_area,
        regexp_match
      )
    }

    context 'when the regexp matches and the range is within the search area' do
      it 'returns a Finding' do
        expect(finding).to be_a described_class
      end
    end

    context 'when the range is outside the search area' do
      let(:search_area) {
        Diakonos::Range.new(
          5, 0,
          5, 5
        )
      }

      it { is_expected.to be_nil }
    end

    context 'when all regexps match on consecutive lines' do
      let(:regexps) { [/hello/, /second/] }

      it 'returns a Finding' do
        expect(finding).to be_a described_class
      end

      it 'extends end_row to the last matched line' do
        expect(finding.end_row).to eq 1
      end
    end

    context 'when a subsequent regexp does not match' do
      let(:regexps) { [/hello/, /nope/] }

      it { is_expected.to be_nil }
    end
  end
end
