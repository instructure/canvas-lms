require 'guard'
require 'guard/plugin'

module Guard
  class Styleguide < Plugin
    def initialize(options={})
      options[:watchers] = [::Guard::Watcher.new(/(app\/stylesheets.*)/)]
      super(options)
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
