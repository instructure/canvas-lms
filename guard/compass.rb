require 'guard'
require 'guard/guard'

module Guard
  class Compass < Guard

    def initialize(watchers=[], options={})
      super([::Guard::Watcher.new(/(app\/stylesheets.*)/)], {})
    end

    def run_on_change(paths)
      # for now just recompile everything, we'll do this more optimized when we
      # fix the TODO below
      run_all
    end

    def run_all
      ::Guard::UI.info "Forcing recompilation of all SASS files"
      # TODO: get rid of this guard and watch sass in our JS based frontend watcher.
      # whatever that ends up being (gulp, broccoli, etc)
      `npm run compile-sass`
    end

  end
end
