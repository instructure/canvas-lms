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
      compile_all
    end

    def run_all
      compile_all force: true
    end

  end
end
