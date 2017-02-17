require 'guard'
require 'guard/plugin'
require 'lib/ember_bundle'

module Guard
  class EmberBundles < Plugin

    DEFAULT_OPTIONS = {
      :hide_success => false,
      :all_on_start => false
    }

    def initialize(options={})
      options[:watchers] = [::Guard::Watcher.new(/(app\/coffeescripts\/ember\/)/)]
      super(options)
    end

    def start
      run_all if options[:all_on_start]
    end

    def run_on_changes(paths)
      build_bundles(paths)
    end

    def build_bundles(paths)
      paths.each do |path|
        return if path.match(/main\.coffee$/)
        begin
          UI.info "Building ember bundle for: #{path}"
          EmberBundle::build_from_file(path)
        rescue Exception => e
          ::Guard::Notifier.notify(e.to_s, :title => path, :image => :failed)
        end
      end
    end

    def run_all
      UI.info "Building all ember bundles"
      Dir.entries('app/coffeescripts/ember').reject {|d| d.match(/^\./) || d == 'shared'}.each do |app|
        EmberBundle.new(app).build
      end
    end
  end
end

