require 'guard'
require 'guard/guard'

module Guard
  class Styleguide < Guard
    def initialize(watchers=[], options={})
      super([::Guard::Watcher.new(/(app\/stylesheets.*)/)], {})
    end

    def run_on_change(paths)
      create_styleguide
    end

    def run_all
      create_styleguide
    end

    def create_styleguide
      puts `dress_code config/styleguide.yml`
    end
  end
end
