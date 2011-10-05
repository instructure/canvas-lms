require 'guard'
require 'guard/guard'
require 'lib/handlebars/handlebars'

module Guard
  class JST < Guard
    # Compiles templates from app/views/jst to public/javascripts/jst
    def run_on_change(paths)
      paths.each do |path|
        begin
          puts "Compiling: #{path}"
          Handlebars.compile_file path, 'app/views/jst', @options[:output]
        rescue Exception => e
          ::Guard::Notifier.notify(e.to_s, :title => path.sub('app/views/jst/', ''), :image => :failed)
        end
      end
    end

  end
end
