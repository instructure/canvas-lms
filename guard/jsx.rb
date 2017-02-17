require 'guard'
require 'guard/plugin'

module Guard
  class JSX < Plugin

    def initialize(options={})
      options[:watchers] = [
        ::Guard::Watcher.new(%r{app/jsx/.*}),
        ::Guard::Watcher.new(%r{spec/javascripts/jsx/.*})
      ]
      super(options)
    end

    def run_on_modifications(paths)
      # naive right now, will be better when we rework the front-end build
      run_all
    end

    def run_all
      ::Guard::UI.info "Compiling JSX"
      [["app/jsx", "public/javascripts/jsx"],
       ["spec/javascripts/jsx", "spec/javascripts/compiled"]].each { |source, dest|
        `node_modules/.bin/babel #{source} --out-dir #{dest} --source-maps inline`
      }
    end

  end
end
