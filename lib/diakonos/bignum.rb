require 'diakonos/keycode'

class Bignum
  include Diakonos::KeyCode
  def ord
    self
  end
end

