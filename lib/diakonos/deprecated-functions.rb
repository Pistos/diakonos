module Diakonos
  module DeprecatedFunctions
    def addNamedBookmark( *args )
      add_named_bookmark *args
    end

    def anchorSelection
      anchor_selection
    end

    def carriageReturn
      carriage_return
    end

    def changeSessionSetting( *args )
      change_session_setting *args
    end

    def clearMatches
      clear_matches
    end

    def closeFile( *args )
      close_file *args
    end

    def collapseWhitespace
      collapse_whitespace
    end

    def copySelection
      copy_selection
    end

    def cursorDown
      cursor_down
    end

    def cursorLeft( *args )
      cursor_left *args
    end

    def cursorRight( *args )
      cursor_right *args
    end

    def cursorUp
      cursor_up
    end

    def cursorBOF
      cursor_bof
    end

    def cursorBOL
      cursor_bol
    end

    def cursorEOL
      cursor_eol
    end

    def cursorEOF
      cursor_eof
    end

    def cursorTOV
      cursor_tov
    end

    def cursorBOV
      cursor_bov
    end

    def cursorReturn( *args )
      cursor_return
    end

    def cutSelection
      cut_selection
    end

    def deleteAndStoreLine
      delete_and_store_line
    end

    def deleteLine
      delete_line
    end

    def deleteToEOL
      delete_to_eol
    end

    def findAgain( *args )
      find_again *args
    end

    def findAndReplace
      find_and_replace
    end

    def findExact( *args )
      find_exact *args
    end

    def goToLineAsk
      go_to_line_ask
    end

    def goToNamedBookmark( *args )
      go_to_named_bookmark
    end

    def goToNextBookmark
      go_to_next_bookmark
    end

    def goToPreviousBookmark
    end

    def goToTag( tag_ = nil )



    end

    def goToTagUnderCursor
    end

    def grep( regexp_source = nil )
    end

    def grep_buffers( regexp_source = nil )
    end

    def grep_session_dir( regexp_source = nil )
    end

    def grep_dir( regexp_source = nil, dir = nil )





    end

    def help( prefill = '' )










    end

    def indent
    end

    def insertSpaces( num_spaces )
    end

    def insertTab
    end

    def joinLines
    end

    def list_buffers
    end

    def loadScript( name_ = nil )


    end

    def load_session( session_id = nil )

    end

    def name_session
    end

    def newFile
    end

    def openFile( filename = nil, read_only = false, force_revert = ASK_REVERT, last_row = nil, last_col = nil )






    end

    def openFileAsk



    end

    def open_matching_files( regexp = nil, search_root = nil )


    end

    def operateOnString(
    )
    end

    def operateOnLines(
    )
    end

    def operateOnEachLine(
    )
    end

    def pageUp
    end

    def pageDown
    end

    def parsedIndent
    end

    def paste
    end

    def paste_from_klipper
    end

    def playMacro( name = nil )
    end

    def popTag
    end

    def print_mapped_function
    end

    def printKeychain
    end

    def quit
    end

    def removeNamedBookmark( name_ = nil )

    end

    def removeSelection
    end

    def repeatLast
    end

    def revert( prompt = nil )


    end

    def saveFile( buffer = @current_buffer )
    end

    def saveFileAs
    end

    def select_all
    end

    def select_block( beginning = nil, ending = nil, including_ending = true )
    end

    def selection_mode_block
    end
    def selection_mode_normal
    end

    def scrollDown
    end

    def scrollUp
    end

    def searchAndReplace( case_sensitive = CASE_INSENSITIVE )
    end

    def seek( regexp_source, dir_str = "down" )
    end

    def setBufferType( type_ = nil )

    end

    def setReadOnly( read_only = nil )
    end

    def set_session_dir
    end

    def showClips
    end

    def subShellVariables( string )









    end

    def shell( command_ = nil, result_filename = 'shell-result.txt' )





    end

    def execute( command_ = nil )





    end

    def pasteShellResult( command_ = nil )




    end

    def spawn( command_ = nil )



    end

    def suspend
    end

    def toggleMacroRecording( name = nil )
    end

    def switchToBufferNumber( buffer_number_ )
    end

    def switchToNextBuffer
    end

    def switchToPreviousBuffer
    end

    def toggleBookmark
    end

    def toggleSelection
    end

    def toggleSessionSetting( key_ = nil, do_redraw = DONT_REDRAW )

    end

    def uncomment
    end

    def undo( buffer = @current_buffer )
    end

    def unindent
    end

    def unundo( buffer = @current_buffer )
    end

    def wrap_paragraph
    end

  end
end
