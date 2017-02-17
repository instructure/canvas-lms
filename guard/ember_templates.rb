require 'guard'
require 'guard/plugin'
require 'handlebars_tasks'

module Guard
  class EmberTemplates < Plugin

    DEFAULT_OPTIONS = {
      :hide_success => false,
      :all_on_start => false
    }

    def initialize(options={})
      options[:watchers] = [::Guard::Watcher.new(/(app\/coffeescripts\/ember\/.*.hbs)\z/)]
      super(options)
    end

    def start
      run_all if options[:all_on_start]
    end

    def run_on_modifications(paths)
      paths.each do |path|
        begin
          UI.info "Compiling Ember template: #{path}"
          HandlebarsTasks::EmberHbs.compile_file path
        rescue Exception => e
          ::Guard::Notifier.notify(e.to_s, :title => path, :image => :failed)
          UI.error "Error compiling: #{path}\n#{e}"
        end
      end
    end

    # Gets called when all files should be regenerated.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def run_all
      UI.info "Compiling all Ember templates"
      files = Dir.glob("app/coffeescripts/**/*.hbs")
      files.each do |file|
        HandlebarsTasks::EmberHbs.compile_file(file)
      end
    end


    def run_on_removals(paths)
      puts "TODO: run_on_removals not implemented"
    end
  end
end

