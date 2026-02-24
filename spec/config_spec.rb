require 'spec_helper'

RSpec.describe 'Diakonos::Diakonos#parse_configuration_file' do
  let(:d) { $diakonos }

  def config_path(filename)
    File.join(File.dirname(__FILE__), 'test-files', 'conf', filename)
  end

  context 'with basic settings' do
    before do
      d.parse_configuration_file(config_path('config-basic.conf'))
    end

    context 'string settings' do
      it 'stores plain string values in settings' do
        expect(d.settings['clipboard.external']).to eq 'xclip'
        expect(d.settings['context.separator']).to eq '---'
        expect(d.settings['diff_command']).to eq 'diff'
        expect(d.settings['session.default_session']).to eq 'my-session'
      end

      it 'strips surrounding quotes from string settings' do
        expect(d.settings['interaction.blink_string']).to eq '***'
        expect(d.settings['status.filler']).to eq '.'
        expect(d.settings['status.left']).to eq ' LFT '
        expect(d.settings['status.modified_str']).to eq '[+]'
        expect(d.settings['status.right']).to eq ' RGT '
        expect(d.settings['status.unnamed_str']).to eq '[unnamed]'
        expect(d.settings['view.line_numbers.number_format']).to eq ' %3d '
      end
    end

    context 'boolean settings' do
      it 'parses true values' do
        expect(d.settings['context.visible']).to be true
        expect(d.settings['eof_newline']).to be true
        expect(d.settings['find.return_on_abort']).to be true
        expect(d.settings['fuzzy_file_find']).to be true
        expect(d.settings['suppress_welcome']).to be true
        expect(d.settings['view.line_numbers']).to be true
      end

      it 'parses false values' do
        expect(d.settings['context.combined']).to be false
        expect(d.settings['convert_tabs']).to be false
        expect(d.settings['fuzzy_file_find.recursive']).to be false
      end
    end

    context 'integer settings' do
      it 'parses integer values' do
        expect(d.settings['async_update_interval']).to eq 200
        expect(d.settings['context.max_levels']).to eq 5
        expect(d.settings['context.max_segment_width']).to eq 40
        expect(d.settings['fuzzy_file_find.max_files']).to eq 500
        expect(d.settings['grep.context']).to eq 3
        expect(d.settings['max_clips']).to eq 20
        expect(d.settings['max_undo_lines']).to eq 100
        expect(d.settings['view.line_numbers.width']).to eq 6
        expect(d.settings['view.lookback']).to eq 10
        expect(d.settings['view.margin.x']).to eq 2
        expect(d.settings['view.margin.y']).to eq 3
        expect(d.settings['view.scroll_amount']).to eq 5
      end

      it 'parses jump values' do
        expect(d.settings['view.jump.x']).to eq 4
        expect(d.settings['view.jump.y']).to eq 6
      end
    end

    context 'float settings' do
      it 'parses float values' do
        expect(d.settings['close_forgotten_buffers_after']).to eq 30.0
        expect(d.settings['context.delay']).to eq 0.25
        expect(d.settings['interaction.blink_duration']).to eq 0.5
        expect(d.settings['interaction.choice_delay']).to eq 1.5
      end
    end

    context 'array settings' do
      it 'splits status.vars into an array' do
        expect(d.settings['status.vars']).to eq %w[type_str filename]
      end
    end

    context 'BOL/EOL behaviour' do
      it 'maps bol_behaviour string to the correct constant' do
        expect(d.settings['bol_behaviour']).to eq Diakonos::BOL_FIRST_CHAR
      end

      it 'maps eol_behaviour string to the correct constant' do
        expect(d.settings['eol_behaviour']).to eq Diakonos::EOL_LAST_CHAR
      end
    end
  end

  context 'with clamped minimum values' do
    before do
      d.parse_configuration_file(config_path('config-clamp.conf'))
    end

    it 'clamps view.jump.x to a minimum of 1' do
      expect(d.settings['view.jump.x']).to eq 1
    end

    it 'clamps view.jump.y to a minimum of 1' do
      expect(d.settings['view.jump.y']).to eq 1
    end

    it 'clamps column marker column to a minimum of 1' do
      expect(d.column_markers['narrow'][:column]).to eq 1
    end
  end

  context 'with language settings' do
    before do
      d.parse_configuration_file(config_path('config-lang.conf'))
    end

    context 'indent regexps' do
      it 'stores indenters as Regexp' do
        expect(d.indenters['ruby']).to be_a Regexp
        expect(d.indenters['ruby']).to match 'def foo'
        expect(d.indenters['ruby']).to match 'class Bar'
      end

      it 'stores unindenters as Regexp' do
        expect(d.unindenters['ruby']).to be_a Regexp
        expect(d.unindenters['ruby']).to match 'end'
        expect(d.unindenters['ruby']).to match 'else'
      end

      it 'stores next-line indenters as Regexp' do
        expect(d.indenters_next_line['ruby']).to be_a Regexp
        expect(d.indenters_next_line['ruby']).to match 'items.each do'
        expect(d.indenters_next_line['ruby']).to match 'proc {'
      end
    end

    context 'indent settings' do
      it 'stores indent size as integer' do
        expect(d.settings['lang.ruby.indent.size']).to eq 2
      end

      it 'stores indent booleans' do
        expect(d.settings['lang.ruby.indent.auto']).to be true
        expect(d.settings['lang.ruby.indent.roundup']).to be false
        expect(d.settings['lang.ruby.indent.using_tabs']).to be false
      end
    end

    context 'indent ignore and context ignore' do
      it 'stores ignore patterns as Regexp in settings' do
        expect(d.settings['lang.ruby.indent.ignore']).to be_a Regexp
        expect(d.settings['lang.ruby.indent.ignore']).to match '# a comment'
      end

      it 'stores preventers pattern as Regexp in settings' do
        expect(d.settings['lang.ruby.indent.preventers']).to be_a Regexp
        expect(d.settings['lang.ruby.indent.preventers']).to match '=begin'
      end

      it 'stores context.ignore as Regexp in settings' do
        expect(d.settings['lang.ruby.context.ignore']).to be_a Regexp
        expect(d.settings['lang.ruby.context.ignore']).to match '# a comment'
      end
    end

    context 'token regexps' do
      it 'stores open token regexps' do
        expect(d.token_regexps['ruby']['comment']).to be_a Regexp
        expect(d.token_regexps['ruby']['comment']).to match '# hello'
      end

      it 'stores open token regexps for named open variant' do
        expect(d.token_regexps['ruby']['string']).to be_a Regexp
        expect(d.token_regexps['ruby']['string']).to match '"'
      end

      it 'stores close token regexps' do
        expect(d.close_token_regexps['ruby']['string']).to be_a Regexp
        expect(d.close_token_regexps['ruby']['string']).to match '"'
      end

      it 'stores case-insensitive token regexps' do
        regexp = d.token_regexps['ruby']['keyword']

        expect(regexp).to be_a Regexp
        expect(regexp).to be_casefold
        expect(regexp).to match 'DEF'
        expect(regexp).to match 'def'
      end
    end

    context 'comment string' do
      it 'stores the comment string with quotes stripped' do
        expect(d.settings['lang.ruby.comment_string']).to eq '#'
      end
    end

    context 'column markers' do
      it 'stores column marker column with minimum of 1' do
        expect(d.column_markers['standard'][:column]).to eq 80
      end
    end
  end

  context 'with comments and blank lines' do
    it 'skips comment lines' do
      d.parse_configuration_file(config_path('config-basic.conf'))

      expect(d.settings).not_to have_key('#')
      expect(d.settings).not_to have_key('# Basic')
    end
  end
end
