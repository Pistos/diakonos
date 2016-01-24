module Diakonos
  class InteractionHandler
    # TODO: Move win_interaction creation, etc. into this class.
    #       If necessary, expose it with attr_reader
    #       e.g. for @modes[ 'input' ].window = @win_interaction
    def initialize(win_main:, win_interaction:, testing: false)
      @win_main = win_main
      @win_interaction = win_interaction
      @testing = testing
    end

    # Display text on the interaction line.
    def set_iline( string = "" )
      return 0  if @testing
      return 0  if $diakonos.readline

      @iline = string
      Curses::curs_set 0
      @win_interaction.setpos( 0, 0 )
      @win_interaction.addstr( "%-#{Curses::cols}s" % @iline )
      @win_interaction.refresh
      Curses::curs_set 1
      string.length
    end

    def set_iline_if_empty( string )
      if @iline.nil? || @iline.empty?
        set_iline string
      end
    end
  end
end