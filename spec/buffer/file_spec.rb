require 'digest/md5'
require 'fileutils'

require 'spec_helper'

RSpec.describe 'Diakonos::Buffer file operations' do

  before do
    FileUtils.mkdir_p(SPEC_TMP)
  end

  after do
    FileUtils.rm_rf(SPEC_TMP)
  end

  def write_tmp_file(name, content)
    path = File.join(SPEC_TMP, name)
    File.write(path, content)
    # Set mtime to the past so subsequent writes are reliably newer
    past = Time.now - 10
    File.utime(past, past, path)

    path
  end

  def buffer_settings(buffer)
    buffer.instance_variable_get(:@settings)
  end

  def new_buffer(filepath:, read_only: Diakonos::Buffer::READ_WRITE)
    Diakonos::Buffer.new(
      'filepath' => filepath,
      'read_only' => read_only,
    )
  end

  describe '#file_modified?' do

    context "when on-disk file has not changed" do
      let(:source) { write_tmp_file('unchanged.txt', "content\n") }
      let(:b) { new_buffer(filepath: source) }

      it 'returns false' do
        expect(b.file_modified?).to be false
      end
    end

    context "when on-disk file has been modified" do
      let(:source) { write_tmp_file('will-change.txt', "original\n") }
      let(:b) { new_buffer(filepath: source) }

      it 'returns true' do
        expect {
          File.write(source, "changed externally\n")
        }.to change {
          b.file_modified?
        }.from(false)
        .to(true)
      end
    end

    context "when called a second time after detecting modification" do
      let(:source) { write_tmp_file('double-check.txt', "original\n") }
      let!(:b) { new_buffer(filepath: source) }

      before do
        File.write(source, "changed externally\n")
        # First call updates @last_modification_check
        b.file_modified?
      end

      it 'returns false' do
        expect(b.file_modified?).to be false
      end
    end

    context "when file does not exist" do
      let(:source) { File.join(SPEC_TMP, 'ghost.txt') }
      let(:b) { new_buffer(filepath: source) }

      it 'returns false' do
        expect(b.file_modified?).to be false
      end
    end

    context "when buffer has no name" do
      let(:b) { new_buffer(filepath: nil) }

      it 'returns false' do
        expect(b.file_modified?).to be false
      end
    end
  end

  describe '#file_different?' do

    context "when buffer matches disk content" do
      let(:source) { write_tmp_file('same.txt', "hello\nworld\n") }
      let(:b) { new_buffer(filepath: source) }

      it 'returns false' do
        expect(b.file_different?).to be false
      end
    end

    context "when buffer content differs from disk" do
      let(:source) { write_tmp_file('differ.txt', "hello\n") }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.instance_variable_set(:@lines, ['changed', ''])
      end

      it 'returns true' do
        expect(b.file_different?).to be true
      end
    end

    context "when file does not exist" do
      let(:path) { File.join(SPEC_TMP, 'nonexistent.txt') }
      let(:b) { new_buffer(filepath: path) }

      it 'returns true' do
        expect(b.file_different?).to be true
      end
    end

    context "when buffer has no name" do
      let(:b) { new_buffer(filepath: nil) }

      it 'returns true' do
        expect(b.file_different?).to be true
      end
    end
  end

  describe '#save' do

    context "when no filename is given" do
      let(:source) { write_tmp_file('save-default.txt', "original\n") }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.save
      end

      it 'writes to the buffer name' do
        expect(File.read(source)).to eq "original\n"
      end
    end

    context "when an alternate filename is provided" do
      let(:source) { write_tmp_file('save-source.txt', "content\n") }
      let(:dest) { File.join(SPEC_TMP, 'save-dest.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.save(dest)
      end

      it 'writes to the alternate file' do
        expect(File.read(dest)).to eq "content\n"
      end

      it 'updates @name to the new filename' do
        expect(b.name).to eq File.expand_path(dest)
      end
    end

    context "when save succeeds" do
      let(:source) { write_tmp_file('save-success.txt', "content\n") }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.insert_string "new content"
      end

      it 'clears the modified flag' do
        expect {
          b.save
        }.to change {
          b.modified?
        }.from(true)
        .to(false)
      end

      it 'returns truthy' do
        expect(b.save).to be_truthy
      end

      it 'updates last_modification_check to the file mtime' do
        t1 = b.instance_variable_get(:@last_modification_check)
        b.save
        t2 = b.instance_variable_get(:@last_modification_check)

        expect(t1).not_to eq t2
        expect(t2).to eq File.mtime(source)
      end
    end

    context "when read-only and saving to the same file" do
      let(:source) { write_tmp_file('read-only.txt', "protected\n") }
      let(:b) do
        new_buffer(
          filepath: source,
          read_only: Diakonos::Buffer::READ_ONLY,
        )
      end

      before do
        expect($diakonos).to receive(:set_iline).with(/read-only/)
      end

      it 'refuses to save' do
        result = b.save

        expect(result).to be_nil
        expect(File.read(source)).to eq "protected\n"
      end
    end

    context "when read-only but saving to a different file" do
      let(:source) { write_tmp_file('ro-source.txt', "protected\n") }
      let(:dest) { File.join(SPEC_TMP, 'ro-dest.txt') }
      let(:b) do
        new_buffer(
          filepath: source,
          read_only: Diakonos::Buffer::READ_ONLY,
        )
      end

      before do
        b.save(dest)
      end

      it 'allows the save' do
        expect(File.read(dest)).to eq "protected\n"
      end
    end

    context "with prompt_overwrite when user chooses yes" do
      let(:source) { write_tmp_file('prompt-source.txt', "new content\n") }
      let(:dest) { write_tmp_file('prompt-dest.txt', "old content\n") }
      let(:b) { new_buffer(filepath: source) }

      before do
        allow($diakonos)
        .to receive(:get_choice)
        .exactly(:once)
        .and_return(Diakonos::CHOICE_YES)
      end

      it 'overwrites the file' do
        b.save(dest, Diakonos::PROMPT_OVERWRITE)

        expect(File.read(dest)).to eq "new content\n"
      end
    end

    context "with prompt_overwrite when user chooses no" do
      let(:source) { write_tmp_file('prompt-no-source.txt', "new content\n") }
      let(:dest) { write_tmp_file('prompt-no-dest.txt', "old content\n") }
      let(:b) { new_buffer(filepath: source) }

      before do
        allow($diakonos)
        .to receive(:get_choice)
        .exactly(:once)
        .and_return(Diakonos::CHOICE_NO)
      end

      it 'does not overwrite the file' do
        b.save(dest, Diakonos::PROMPT_OVERWRITE)

        expect(File.read(dest)).to eq "old content\n"
      end
    end

    context "with prompt_overwrite when dest file does not exist yet" do
      let(:source) { write_tmp_file('prompt-new-source.txt', "content\n") }
      let(:dest) { File.join(SPEC_TMP, 'prompt-new-dest.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        expect($diakonos).not_to receive(:get_choice)
      end

      it 'saves without prompting' do
        b.save(dest, Diakonos::PROMPT_OVERWRITE)

        expect(File.read(dest)).to eq "content\n"
      end
    end

    context "when file has been externally modified and user reverts" do
      let(:source) { write_tmp_file('ext-mod.txt', "original\n") }
      let!(:b) { new_buffer(filepath: source) }

      before do
        File.write(source, "changed externally\n")
        allow($diakonos).to receive(:revert).and_return(true)
      end

      it 'does not save' do
        expect(b.save).to be_nil
      end
    end

    context "when file has been externally modified and user declines to revert" do
      let(:source) { write_tmp_file('ext-mod-save.txt', "original\n") }
      let!(:b) { new_buffer(filepath: source) }

      before do
        File.write(source, "changed externally\n")
        allow($diakonos).to receive(:revert).and_return(false)
      end

      it 'saves' do
        expect(b.save).to be_truthy
      end
    end

    context "when saving a config file" do
      let(:config_dir) { $diakonos.diakonos_home }
      let(:config_path) { File.join(config_dir, 'test-reload.conf') }
      let(:b) { new_buffer(filepath: config_path) }

      before do
        FileUtils.mkdir_p(config_dir)
        File.write(config_path, "# test config\n")
      end

      after do
        FileUtils.rm_f(config_path)
      end

      it 'reloads configuration' do
        expect($diakonos).to receive(:load_configuration)
        expect($diakonos).to receive(:initialize_display)

        b.save
      end
    end

    context "when buffer has nil name and no filename given" do
      let(:b) { new_buffer(filepath: nil) }

      it 'delegates to save_file_as' do
        expect($diakonos).to receive(:save_file_as)

        b.save
      end
    end
  end

  describe '#save_copy' do

    context "when writing to a new file" do
      let(:source) { write_tmp_file('source.txt', "line one\nline two\n") }
      let(:dest) { File.join(SPEC_TMP, 'dest.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.save_copy(dest)
      end

      it 'writes buffer contents' do
        expect(File.read(dest)).to eq "line one\nline two\n"
      end
    end

    context "when filename is nil" do
      let(:source) { write_tmp_file('source.txt', "hello\n") }
      let(:b) { new_buffer(filepath: source) }

      it 'returns false' do
        expect(b.save_copy(nil)).to eq false
      end
    end

    context "with strip_trailing_whitespace_on_save enabled" do
      let(:b) { new_buffer(filepath: source) }
      let(:dest) { File.join(SPEC_TMP, 'stripped.txt') }

      before do
        buffer_settings(b)['strip_trailing_whitespace_on_save'] = true
      end

      context "when interior lines have trailing whitespace" do
        let(:source) do
          write_tmp_file(
            'trailing.txt',
            "no trailing\nhas trailing   \nalso trailing\t\n"
          )
        end

        before do
          b.save_copy(dest)
        end

        it 'strips trailing whitespace from all lines' do
          expect(File.read(dest)).to eq "no trailing\nhas trailing\nalso trailing\n"
        end
      end

      context "when the final line has trailing whitespace" do
        let(:source) do
          write_tmp_file('trailing-last.txt', "first\nlast with spaces   ")
        end

        before do
          buffer_settings(b)['eof_newline'] = false
          b.save_copy(dest)
        end

        it 'strips trailing whitespace from the final line' do
          expect(File.read(dest)).to eq "first\nlast with spaces"
        end
      end
    end

    context "with strip_trailing_whitespace_on_save disabled" do
      let(:source) do
        write_tmp_file(
          'keep-trailing.txt',
          "has trailing   \nalso trailing\t\n"
        )
      end
      let(:dest) { File.join(SPEC_TMP, 'kept.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        buffer_settings(b)['strip_trailing_whitespace_on_save'] = false
        b.save_copy(dest)
      end

      it 'preserves trailing whitespace' do
        expect(File.read(dest)).to eq "has trailing   \nalso trailing\t\n"
      end
    end

    context "with eof_newline enabled" do
      let(:b) { new_buffer(filepath: source) }
      let(:dest) { File.join(SPEC_TMP, 'eof-nl.txt') }

      before do
        buffer_settings(b)['eof_newline'] = true
        b.save_copy(dest)
      end

      context "when file does not end with a newline" do
        let(:source) { write_tmp_file('no-eof-nl.txt', "line one\nline two") }

        it 'appends a newline' do
          expect(File.read(dest)).to eq "line one\nline two\n"
        end
      end

      context "when file already ends with a newline" do
        let(:source) { write_tmp_file('has-eof-nl.txt', "line one\nline two\n") }

        it 'does not double the newline' do
          expect(File.read(dest)).to eq "line one\nline two\n"
        end
      end
    end

    context "with eof_newline disabled" do
      let(:source) { write_tmp_file('no-eof-nl2.txt', "line one\nline two") }
      let(:dest) { File.join(SPEC_TMP, 'no-eof-nl2-out.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        buffer_settings(b)['eof_newline'] = false
        b.save_copy(dest)
      end

      it 'preserves absence of trailing newline' do
        expect(File.read(dest)).to eq "line one\nline two"
      end
    end

    context "with save_backup_files enabled" do
      let(:b) { new_buffer(filepath: source) }

      before do
        buffer_settings(b)['save_backup_files'] = true
      end

      context "when overwriting an existing file" do
        let(:source) { write_tmp_file('backup-source.txt', "new content\n") }
        let(:dest) { write_tmp_file('backup-target.txt', "original content\n") }
        let(:backup_path) { dest + '~' }

        before do
          b.save_copy(dest)
        end

        it 'creates a backup of the original' do
          expect(File.exist?(backup_path)).to be true
          expect(File.read(backup_path)).to eq "original content\n"
        end

        it 'writes the new content' do
          expect(File.read(dest)).to eq "new content\n"
        end
      end

      context "when saving to a new file" do
        let(:source) { write_tmp_file('backup-new-source.txt', "content\n") }
        let(:dest) { File.join(SPEC_TMP, 'nonexistent-target.txt') }

        it 'does not fail' do
          expect { b.save_copy(dest) }.not_to raise_error
          expect(File.read(dest)).to eq "content\n"
        end
      end
    end

    context "with save_backup_files disabled" do
      let(:dest) { write_tmp_file('no-backup-target.txt', "original\n") }
      let(:source) { write_tmp_file('no-backup-source.txt', "new\n") }
      let(:b) { new_buffer(filepath: source) }

      before do
        buffer_settings(b)['save_backup_files'] = false
        b.save_copy(dest)
      end

      it 'does not create a backup file' do
        expect(File.exist?(dest + '~')).to be false
      end

      it 'writes the new content' do
        expect(File.read(dest)).to eq "new\n"
      end
    end

    context "when buffer is empty" do
      let(:source) { write_tmp_file('empty.txt', "") }
      let(:dest) { File.join(SPEC_TMP, 'empty-out.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.save_copy(dest)
      end

      it 'writes an empty file' do
        expect(File.read(dest)).to eq ""
      end
    end

    context "when buffer is a single newline" do
      let(:source) { write_tmp_file('single-nl.txt', "\n") }
      let(:dest) { File.join(SPEC_TMP, 'single-nl-out.txt') }
      let(:b) { new_buffer(filepath: source) }

      before do
        b.save_copy(dest)
      end

      it 'writes a single newline' do
        expect(File.read(dest)).to eq "\n"
      end
    end
  end
end
