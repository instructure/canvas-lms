require 'guard'
require 'guard/guard'
require 'lib/multi_variant_compass_compiler'

module Guard
  class Compass < Guard

    include MultiVariantCompassCompiler

    def initialize(watchers=[], options={})
      super([::Guard::Watcher.new(/(app\/stylesheets.*)/)], {})
    end

    def run_on_change(paths)
      ::Guard::UI.info "Recompiling SASS files that have changed"
      compile_all environment: :development
    end

    def run_all
      ::Guard::UI.info "Forcing recompilation of all SASS files"
      compile_all force: true, environment: :development
    end

  end
end
