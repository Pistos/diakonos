module Diakonos
  class Diakonos
    def init_help
      @help_dir = INSTALL_SETTINGS[ :help_dir ]
      @help_tags = `grep -h Tags #{@help_dir}/* | cut -d ' ' -f 2-`.split.uniq
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