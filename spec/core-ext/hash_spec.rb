require 'spec_helper'

RSpec.describe Hash do
  describe '#delete_key_path' do
    subject(:deletion) {
      hash.delete_key_path(path)
    }

    context 'given a simple Hash' do
      let(:hash) {
        { a: 1, b: 2 }
      }

      context 'when path has one element' do
        let(:path) { [:a] }

        it 'deletes the key' do
          expect {
            deletion
          }.to change {
            hash.include?(:a)
          }.from(true)
          .to(false)
        end

        it 'returns the Hash' do
          expect(deletion).to be hash
        end
      end
    end

    context 'given a Hash with a nested Hash value' do
      let(:hash) {
        { a: { b: 2 }, c: 3 }
      }

      context 'when path targets the nested value' do
        let(:path) { [:a, :b] }

        it 'deletes the leaf and prunes empty parent nodes' do
          expect {
            deletion
          }.to change {
            hash.include?(:a)
          }.from(true)
          .to(false)
        end

        it 'returns the Hash' do
          expect(deletion).to be hash
        end
      end
    end

    context 'given a flat Hash with no nesting' do
      let(:hash) {
        { a: 42, b: 2 }
      }

      context 'when path depth is more than 1' do
        let(:path) { [:a, :nested] }

        it 'makes no changes' do
          expect {
            deletion
          }.not_to change {
            hash.dup
          }
        end

        it 'returns the Hash' do
          expect(deletion).to be hash
        end
      end
    end
  end

  describe '#get_leaf' do
    subject(:leaf) { hash.get_leaf(path) }

    context 'given a Hash with nesting' do
      let(:hash) {
        { a: { b: 2 }, c: 3 }
      }

      context 'when path points to a leaf one level deep' do
        let(:path) { [:c] }

        it 'returns the leaf value' do
          expect(leaf).to eq 3
        end
      end

      context 'when path points to a branch node' do
        let(:path) { [:a] }

        it { is_expected.to be_nil }
      end

      context 'when path points to a nested leaf value' do
        let(:path) { [:a, :b] }

        it 'returns the leaf value' do
          expect(leaf).to eq 2
        end
      end

      context 'when path does not exist' do
        let(:path) { [:z] }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#get_node' do
    subject(:node) { hash.get_node(path) }

    context 'given a Hash with nested and first-level values' do
      let(:hash) {
        { a: { b: 3 }, d: 4 }
      }

      context 'when path points to a leaf one level deep' do
        let(:path) { [:d] }

        it 'returns the leaf value' do
          expect(node).to eq 4
        end
      end

      context 'when path points to a branch node' do
        let(:path) { [:a] }

        it 'returns the nested Hash' do
          expect(node).to eq( {b: 3} )
        end
      end

      context 'when path points to a nested leaf' do
        let(:path) { [:a, :b] }

        it 'returns the nested value' do
          expect(node).to eq 3
        end
      end

      context 'when path points to a missing key' do
        let(:path) { [:z] }

        it { is_expected.to be_nil }
      end

      context 'when path descends past a missing key' do
        let(:path) { [:e, :x] }

        it { is_expected.to be_nil }
      end

      context 'when a nested key is missing' do
        let(:path) { [:a, :z] }
        it { is_expected.to be_nil }

      end
    end
  end

  describe '#set_key_path' do
    subject(:retval) {
      hash.set_key_path(path, value)
    }

    context 'given an empty Hash' do
      let(:hash) { {} }

      context 'when path has one element' do
        let(:path) { [:x] }
        let(:value) { 99 }

        it 'sets the key' do
          expect {
            retval
          }.to change {
            hash[:x]
          }.from(nil)
          .to(99)
        end

        it 'returns the Hash' do
          expect(retval).to be hash
        end
      end

      context 'when path has multiple elements' do
        let(:path) { [:a, :b] }
        let(:value) { 'val' }

        it 'creates nested hashes and sets the leaf value' do
          expect {
            retval
          }.to change {
            hash[:a]
          }.from(nil)
          .to( {b: 'val'} )
        end
      end
    end

    context 'given a Hash with a leaf' do
      let(:hash) {
        { a: 42 }
      }

      context 'when the path passes through that leaf key' do
        let(:path) { [:a, :b] }
        let(:value) { 'val' }

        it 'replaces the leaf with a nested Hash' do
          expect {
            retval
          }.to change {
            hash[:a]
          }.from(42)
          .to({ b: 'val' })
        end
      end
    end
  end
end
