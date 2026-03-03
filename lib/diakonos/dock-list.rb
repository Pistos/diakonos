module Diakonos
  class DockList
    attr_reader :items, :selected_index

    def initialize(items:)
      @items = items
      @selected_index = 0
    end

    def display_lines
      @items
    end

    def next_item
      if @selected_index < @items.length - 1
        @selected_index += 1
      end

      selected_item
    end

    def previous_item
      if @selected_index > 0
        @selected_index -= 1
      end

      selected_item
    end

    def selected_item
      @items[@selected_index]
    end
  end
end
