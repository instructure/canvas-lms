require 'guard'
require 'guard/guard'
require 'lib/handlebars/handlebars'

module Guard
  class JST < Guard
    # Compiles templates from app/views/jst to public/javascripts/jst
    def run_on_change(paths)
      paths.each do |path|
        puts "Running #{path}"
        Handlebars.compile_file path, 'app/views/jst', @options[:output]
      end
    end
  end
end
