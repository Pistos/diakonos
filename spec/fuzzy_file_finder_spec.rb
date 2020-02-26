require 'spec_helper'

RSpec.describe FuzzyFileFinder do
  let(:params) {
    {
      ceiling: ceiling,
      directories: directories,
      ignores: ignores,
      recursive: recursive,
    }
  }
  let(:finder) { described_class.new(params) }

  let(:ceiling) { nil }
  let(:directories) { ['spec/test-files'] }
  let(:ignores) { [] }
  let(:recursive) { nil }

  describe "#find" do
    let(:matches) {
      finder.find(input).map { |match|
        match[:path].gsub(/^#{__dir__}/, '')
      }
    }

    context "basic input" do
      let(:input) { 'lo' }

      it "finds the matching files" do
        expect(matches).to eq [
          '/test-files/longer-sample-file.rb',
          '/test-files/lorem-ipsum.txt',
        ]
      end
    end
  end
end
