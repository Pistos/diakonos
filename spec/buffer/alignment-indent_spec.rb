require 'spec_helper'

RSpec.describe 'Clojure alignment-based indentation' do
  let(:buffer) { Diakonos::Buffer.new('filepath' => sample_file) }
  let(:sample_file) { File.join(TEST_DIR, 'sample.clj') }
  let(:temp_file) {
    FileUtils.mkdir_p SPEC_TMP
    File.join( SPEC_TMP, 'alignment-indent.clj' )
  }

  let(:expected_contents) { File.read(sample_file) }

  def reindent_all( buf )
    (0...buf.length).each do |row|
      buf.parsed_indent  row:, do_display: false
    end
  end

  context 'when indentation is already correct' do
    it 'is idempotent (does not change the buffer)' do
      reindent_all buffer
      buffer.save_copy temp_file
      expect(File.read(temp_file)).to eq expected_contents
    end

    it 'remains correct after a second pass' do
      reindent_all buffer
      reindent_all buffer
      buffer.save_copy temp_file
      expect(File.read(temp_file)).to eq expected_contents
    end
  end

  context 'when indentation is disturbed' do
    before do
      [1, 2, 5, 7, 11, 12, 16, 19, 22, 24, 29, 30].each do |row|
        buffer.cursor_to( row, 0 )
        buffer.insert_string "   "
      end
    end

    it 'restores correct indentation on reindent' do
      reindent_all buffer
      buffer.save_copy temp_file
      expect(File.read(temp_file)).to eq expected_contents
    end
  end

  context 'structural cases' do
    before do
      reindent_all buffer
    end

    def indent_of( row )
      buffer[ row ][ /\A */ ].length
    end

    it 'aligns function-call arguments to first argument column' do
      # (println "Result:"\n<align here>total)))
      expect(indent_of( 17 )).to eq 13
    end

    it 'body-indents special forms (defn, let) by 2' do
      # (defn greet\n  "Greet someone..."
      expect(indent_of( 5 )).to eq 2
      # (defn greet\n  ...[name])
      expect(indent_of( 7 )).to eq 2
      # (let [...]\n    (println ...))  — inside defn body, then let body
      expect(indent_of( 16 )).to eq 4
    end

    it 'aligns vector contents to column after [' do
      # [1 2 3\n<7 spaces>4 5 6]
      expect(indent_of( 22 )).to eq 12
    end

    it 'aligns map contents to column after {' do
      # Row 20 is the map itself, body of (def data) — col 2
      expect(indent_of( 20 )).to eq 2
      # Rows 21, 23 are contents of outer map — col 3 (after { at col 2)
      expect(indent_of( 21 )).to eq 3
      expect(indent_of( 23 )).to eq 3
      # Nested {:a 1\n<12 spaces>:b 2}}) — { at col 11, contents at 12
      expect(indent_of( 24 )).to eq 12
    end

    it 'aligns :require library vector contents to first library' do
      # (:require [clojure.string :as str]\n<12 spaces>[clojure.set ...])
      expect(indent_of( 2 )).to eq 12
    end
  end
end
