require 'guard'
require 'guard/guard'

module Guard
  class JSX < Guard

    def initialize(watchers=[], options={})
      super([::Guard::Watcher.new(%r{app/jsx/.*}),
             ::Guard::Watcher.new(%r{spec/javascripts/jsx/.*})], {})
    end

    def run_on_change(paths)
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

