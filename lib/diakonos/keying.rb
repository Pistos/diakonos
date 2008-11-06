module Diakonos
  class Diakonos
    def capture_keychain( c, context )
      if c == ENTER
        @capturing_keychain = false
        @current_buffer.deleteSelection
        str = context.to_keychain_s.strip
        @current_buffer.insertString str 
        cursorRight( Buffer::STILL_TYPING, str.length )
      else
        keychain_pressed = context.concat [ c ]
        
        function_and_args = @keychains.getLeaf( keychain_pressed )
        
        if function_and_args
          function, args = function_and_args
        end
        
        partial_keychain = @keychains.getNode( keychain_pressed )
        if partial_keychain
          setILine( "Part of existing keychain: " + keychain_pressed.to_keychain_s + "..." )
        else
          setILine keychain_pressed.to_keychain_s + "..."
        end
        processKeystroke( keychain_pressed )
      end
    end
    
    def capture_mapping( c, context )
      if c == ENTER
        @capturing_mapping = false
        @current_buffer.deleteSelection
        setILine
      else
        keychain_pressed = context.concat [ c ]
        
        function_and_args = @keychains.getLeaf( keychain_pressed )
        
        if function_and_args
          function, args = function_and_args
          setILine "#{keychain_pressed.to_keychain_s.strip}  ->  #{function}( #{args} )"
        else
          partial_keychain = @keychains.getNode( keychain_pressed )
          if partial_keychain
            setILine( "Several mappings start with: " + keychain_pressed.to_keychain_s + "..." )
            processKeystroke( keychain_pressed )
          else
            setILine "There is no mapping for " + keychain_pressed.to_keychain_s
          end
        end
      end
    end
    
    # context is an array of characters (bytes) which are keystrokes previously
    # typed (in a chain of keystrokes)
    def processKeystroke( context = [] )
      c = @win_main.getch
        
      if @capturing_keychain
        capture_keychain c, context
      elsif @capturing_mapping
        capture_mapping c, context
      else
        
        if context.empty?
          if c > 31 and c < 255 and c != BACKSPACE
            if @macro_history
              @macro_history.push "typeCharacter #{c}"
            end
            @there_was_non_movement = true
            typeCharacter c
            return
          end
        end
        keychain_pressed = context.concat [ c ]
            
        function_and_args = @keychains.getLeaf( keychain_pressed )
        
        if function_and_args
          function, args = function_and_args
          setILine if not @settings[ "context.combined" ]
          
          if args
            to_eval = "#{function}( #{args} )"
          else
            to_eval = function
          end
          
          if @macro_history
            @macro_history.push to_eval
          end
          
          begin
            eval to_eval, nil, "eval"
            @last_commands << to_eval unless to_eval == "repeatLast"
            if not @there_was_non_movement
              @there_was_non_movement = ( not to_eval.movement? )
            end
          rescue Exception => e
            debugLog e.message
            debugLog e.backtrace.join( "\n\t" )
            showException e
          end
        else
          partial_keychain = @keychains.getNode( keychain_pressed )
          if partial_keychain
            setILine( keychain_pressed.to_keychain_s + "..." )
            processKeystroke( keychain_pressed )
          else
            setILine "Nothing assigned to #{keychain_pressed.to_keychain_s}"
          end
        end
      end
    end
    protected :processKeystroke

    def typeCharacter( c )
      @current_buffer.deleteSelection( Buffer::DONT_DISPLAY )
      @current_buffer.insertChar c
      cursorRight( Buffer::STILL_TYPING )
    end
    
  end
end