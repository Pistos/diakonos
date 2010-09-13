module Diakonos
  module Functions

    def go_to_tag( tag_ = nil )
      load_tags

      # If necessary, prompt for tag name.

      if tag_.nil?
        if buffer_current.changing_selection
          selected_text = buffer_current.copy_selection[ 0 ]
        end
        tag_name = get_user_input(
          "Tag name: ",
          history: @rlh_general,
          initial_text: selected_text || "",
          completion_array: @tags.keys
        )
      else
        tag_name = tag_
      end

      tag_array = @tags[ tag_name ]
      if tag_array and tag_array.length > 0
        if i = tag_array.index( @last_tag )
          tag = ( tag_array[ i + 1 ] or tag_array[ 0 ] )
        else
          tag = tag_array[ 0 ]
        end
        @last_tag = tag
        @tag_stack.push [ buffer_current.name, buffer_current.last_row, buffer_current.last_col ]
        if switch_to( @buffers.find { |b| b.name == tag.file } )
          #buffer_current.go_to_line( 0 )
        else
          open_file tag.file
        end
        line_number = tag.command.to_i
        if line_number > 0
          buffer_current.go_to_line( line_number - 1 )
        else
          find( "down", CASE_SENSITIVE, tag.command )
        end
      elsif tag_name
        set_iline "No such tag: '#{tag_name}'"
      end
    end

    def go_to_tag_under_cursor
      go_to_tag buffer_current.word_under_cursor
    end

    def pop_tag
      tag = @tag_stack.pop
      if tag
        if not switch_to( @buffers.find { |b| b.name == tag[ 0 ] } )
          open_file tag[ 0 ]
        end
        buffer_current.cursor_to( tag[ 1 ], tag[ 2 ], Buffer::DO_DISPLAY )
      else
        set_iline "Tag stack empty."
      end
    end

  end
end