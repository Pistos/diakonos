module Diakonos
  class Diakonos

    def about_write
      File.open( @about_filename, "w" ) do |f|
        f.puts %{
# About Diakonos

## Version Information

Version:      #{::Diakonos::VERSION}
        }.strip
      end
    end

  end
end