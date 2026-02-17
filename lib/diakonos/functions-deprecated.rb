module Diakonos
  # These camel-cased method names are defined here to support legacy
  # configuration files.

  class Diakonos
    alias loadConfiguration load_configuration
  end

  module Functions
    alias addNamedBookmark add_named_bookmark
    alias anchorSelection anchor_selection
    alias carriageReturn carriage_return
    alias changeSessionSetting change_session_setting
    alias clearMatches clear_matches
    alias closeFile close_buffer
    alias close_file close_buffer
    alias collapseWhitespace collapse_whitespace
    alias copySelection copy_selection
    alias cursorDown cursor_down
    alias cursorLeft cursor_left
    alias cursorRight cursor_right
    alias cursorUp cursor_up
    alias cursorBOF cursor_bof
    alias cursorBOL cursor_bol
    alias cursorEOL cursor_eol
    alias cursorEOF cursor_eof
    alias cursorTOV cursor_tov
    alias cursorBOV cursor_bov
    alias cursorReturn cursor_return
    alias cutSelection cut_selection
    alias deleteAndStoreLine delete_and_store_line
    alias deleteLine delete_line
    alias deleteToEOL delete_to_eol
    alias findAgain find_again
    alias findAndReplace search_and_replace
    alias findExact find_exact
    alias goToLineAsk go_to_line_ask
    alias goToNamedBookmark go_to_named_bookmark
    alias goToNextBookmark go_to_next_bookmark
    alias goToPreviousBookmark go_to_previous_bookmark
    alias goToTag go_to_tag
    alias goToTagUnderCursor go_to_tag_under_cursor
    alias insertSpaces insert_spaces
    alias insertTab insert_tab
    alias joinLines join_lines
    alias loadScript load_script
    alias newFile open_file
    alias openFile open_file
    alias openFileAsk open_file_ask
    alias operateOnString operate_on_string
    alias operateOnLines operate_on_lines
    alias operateOnEachLine operate_on_each_line
    alias pageUp page_up
    alias pageDown page_down
    alias parsedIndent parsed_indent
    alias playMacro play_macro
    alias popTag pop_tag
    alias printKeychain print_keychain
    alias removeNamedBookmark remove_named_bookmark
    alias removeSelection remove_selection
    alias repeatLast repeat_last
    alias saveFile save_file
    alias saveFileAs save_file_as
    alias scrollDown scroll_down
    alias scrollUp scroll_up
    alias searchAndReplace search_and_replace
    alias setBufferType set_buffer_type
    alias setReadOnly set_read_only
    alias showClips show_clips
    alias pasteShellResult paste_shell_result
    alias toggleMacroRecording toggle_macro_recording
    alias switchToBufferNumber switch_to_buffer_number
    alias switchToNextBuffer switch_to_next_buffer
    alias switchToPreviousBuffer switch_to_previous_buffer
    alias toggleBookmark toggle_bookmark
    alias toggleSelection toggle_selection
    alias toggleSessionSetting toggle_session_setting
  end
end
