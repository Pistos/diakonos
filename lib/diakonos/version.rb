module Diakonos
  VERSION = '0.10.1'
  LAST_MODIFIED = '2026-05-07'

  def self.parse_version(s)
    s
    &.split( '.' )
    &.map(&:to_i)
    &.extend(Comparable)
  end

  def self.check_ruby_version
    ruby_version = parse_version(RUBY_VERSION)

    if ruby_version < [ 3, 1 ]
      warn "This version of Diakonos (#{Diakonos::VERSION}) requires Ruby 3.1 or higher."

      if ruby_version >= [ 3, 0 ]
        warn "Version 0.9.12 is the last version of Diakonos which can run under Ruby 3.0."
      elsif ruby_version >= [ 2, 0 ]
        warn "Version 0.9.5 is the last version of Diakonos which can run under Ruby 2.0."
      elsif ruby_version >= [ 1, 9 ]
        warn "Version 0.9.2 is the last version of Diakonos which can run under Ruby 1.9."
      elsif ruby_version >= [ 1, 8 ]
        warn "Version 0.8.9 is the last version of Diakonos which can run under Ruby 1.8."
      end

      exit 1
    end
  end
end
