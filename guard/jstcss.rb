require 'guard'
require 'guard/guard'
require 'fileutils'

# The only thing this guard does is make sure to touch the
# handlebars file if you edit something in app/stylesheets.
# doing so will trigger the handlebars guard to regenerate the
# .handlebars file with the new css injected into
module Guard
  class JSTCSS < Guard

    def initialize(watchers = [], options = {})
      watchers = [] if !watchers

      if options[:input]
        watchers << ::Guard::Watcher.new(%r{\A(?:vendor/plugins/.*?/)?#{ Regexp.escape(options[:input]) }/(.+\.s[ca]ss)\z})
      end

      super(watchers, options)
    end

    def run_on_change(paths)
      paths.each { |p| touch_handlebars_file(p) }
    end

    def touch_handlebars_file(sass_path)
      hbs_path = path.sub('stylesheets', 'views').sub(/\.([^\.]*)\z/, '.handlebars')
      FileUtils.touch(hbs_path) if File.exist?(hbs_path)
    end

  end
end