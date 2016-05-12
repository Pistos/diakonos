module Diakonos
  VERSION       = '0.9.6'
  LAST_MODIFIED = 'May 11, 2016'

  def self.parse_version( s )
    if s
      s.split( '.' ).map { |part| part.to_i }.extend( Comparable )
    end
  end

  def self.check_ruby_version
    ruby_version = parse_version( RUBY_VERSION )
    if ruby_version < [ 2, 1 ]
      $stderr.puts "This version of Diakonos (#{Diakonos::VERSION}) requires Ruby 2.1, 2.2 or 2.3."
      if ruby_version >= [ 2, 0 ]
        $stderr.puts "Version 0.9.5 is the last version of Diakonos which can run under Ruby 2.0."
      elsif ruby_version >= [ 1, 9 ]
        $stderr.puts "Version 0.9.2 is the last version of Diakonos which can run under Ruby 1.9."
      elsif ruby_version >= [ 1, 8 ]
        $stderr.puts "Version 0.8.9 is the last version of Diakonos which can run under Ruby 1.8."
      end
      exit 1
    end
  end
end
