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
  let(:root_dir) { "spec/test-files" }
  let(:directories) { [root_dir] }
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
        expect(matches.sort).to eq [
          '/test-files/longer-sample-file.rb',
          '/test-files/lorem-ipsum.txt',
        ]
      end
    end

    context "when the ceiling is less than the number of entries searched" do
      let(:ceiling) { 5 }

      it "raises a TooManyEntries exception" do
        expect { finder.find(input) }
        .to raise_exception(FuzzyFileFinder::TooManyEntries, %r[14.*#{root_dir}])
      end
    end
  end
end
