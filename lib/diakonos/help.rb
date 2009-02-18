module Diakonos
  class Diakonos
    def init_help
      return  if @testing

      @base_help_dir = "#{@diakonos_home}/help"
      mkdir @base_help_dir

      @help_dir = "#{@diakonos_home}/help/#{VERSION}"
      if not File.exist?( @help_dir ) or Dir[ "#{@help_dir}/*" ].size == 0
        puts "Help files for this Diakonos version were not found (#{@help_dir})."

        puts "Would you like to download the help files right now from the Diakonos website? (y/n)"
        answer = $stdin.gets
        case answer
        when /^y/i
          if not fetch_help
            $stderr.puts "Failed to get help for version #{VERSION}."
            sleep 2
          end
        end
      end

      @help_tags = `grep -h Tags #{@help_dir}/* | cut -d ' ' -f 2-`.split.uniq
    end

    def fetch_help
      require 'open-uri'
      success = false
      puts "Fetching help documents for version #{VERSION}..."

      filename = "diakonos-help-#{VERSION}.tar.gz"
      uri = "http://purepistos.net/diakonos/#{filename}"
      tarball = "#{@base_help_dir}/#{filename}"
      begin
        open( uri ) do |http|
          bytes = http.read
          File.open( tarball, 'w' ) do |f|
            f.print bytes
          end
        end
        mkdir @help_dir
        `tar zxf #{tarball} -C #{@base_help_dir}`
        success = true
      rescue OpenURI::HTTPError => e
        $stderr.puts "Failed to fetch from #{uri} ."
      end

      success
    end

    def open_help_buffer
      @help_buffer = openFile( @help_filename )
    end
    def close_help_buffer
      closeFile @help_buffer
      @help_buffer = nil
    end

    def matching_help_documents( str )
      docs = []

      if str =~ %r{^/(.+)$}
        regexp = $1
        files = Dir[ "#{@help_dir}/*" ].select{ |f|
          File.open( f ) { |io| io.grep( /#{regexp}/i ) }.any?
        }
      else
        terms = str.gsub( /[^a-zA-Z0-9-]/, ' ' ).split.join( '|' )
        file_grep = `egrep -i -l '^Tags.*\\b(#{terms})\\b' #{@help_dir}/*`
        files = file_grep.split( /\s+/ )
      end

      files.each do |file|
        File.open( file ) do |f|
          docs << ( "%-300s | %s" % [ f.gets.strip, file ] )
        end
      end

      docs.sort { |a,b| a.gsub( /^# (?:an?|the) */i, '# ' ) <=> b.gsub( /^# (?:an?|the) */i, '# ' ) }
    end

    def open_help_document( selected_string )
      help_file = selected_string.split( "| " )[ -1 ]
      if File.exist? help_file
        openFile help_file
      end
    end

  end
end