require 'guard'
require 'guard/guard'
require 'fileutils'
require 'compass-rails'
require 'sass/plugin'

module Guard
  class JSTCSS < Guard


    DEFAULT_OPTIONS = {
      :hide_success => false,
      :all_on_start => false
    }

    def initialize(watchers = [], options = {})
      watchers = [] if !watchers
      defaults = DEFAULT_OPTIONS.clone

      if options[:input]
        defaults.merge!({ :output => options[:input] })
        watchers << ::Guard::Watcher.new(%r{\A(?:vendor/plugins/.*?/)?#{ Regexp.escape(options[:input]) }/(.+\.s[ca]ss)\z})
      end

      super(watchers, defaults.merge(options))
    end

    def start
      run_all if options[:all_on_start]
    end

    def update_jst_css(paths, remove = false)
      paths.each do |path|
        # update (or delete) css
        css_path = path.sub(@options[:input], @options[:output]).sub(/\.s[ca]ss\z/, '.css')
        if remove
          File.delete(css_path) if File.exist?(css_path)
        else
          Compass.compiler.compile path, css_path
        end

        # now make sure hbs gets recompiled (via other guard)
        hbs_path = path.sub('stylesheets', 'views').sub(/\.([^\.]*)\z/, '.handlebars')
        FileUtils.touch(hbs_path) if File.exist?(hbs_path)
      end
    end

    def run_on_change(paths)
      update_jst_css paths
    end

    def run_all
      UI.info "Compiling all jst css in #{@options[:input]} to #{@options[:output]}"
      update_jst_css Dir["{,vendor/plugins/*/}app/stylesheets/jst/**/*.s{c,a}ss"]
      UI.info "Successfully compiled all jst css in #{@options[:input]}"
    end

    def run_on_deletion(paths)
      update_jst_css paths, :remove
    end

  end
end
