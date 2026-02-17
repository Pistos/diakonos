module Diakonos
  class NumberFitter
    def self.fit(number:, min:, max:)
      return number  if max < min
      return min  if number < min
      return max  if number > max

      number
    end
  end
end
