require 'guard'
require 'guard/plugin'
require 'fileutils'
require 'handlebars_tasks'
require 'parallel'

module Guard
  class JST < Plugin


    DEFAULT_OPTIONS = {
      :hide_success => false,
      :all_on_start => false
    }

    # Initialize Guard::JST.
    #
    # @param [Hash] options the options for the Guard
    # @option options [String] :input the input directory
    # @option options [String] :output the output directory
    # @option options [Boolean] :hide_success hide success message notification
    # @option options [Boolean] :all_on_start generate all JavaScripts files on start
    #
    def initialize(options = {})
      options[:watchers] ||= []
      defaults = DEFAULT_OPTIONS.clone

      if options[:input]
        defaults.merge!({ :output => options[:input] })
        options[:watchers] << ::Guard::Watcher.new(%r{\A(?:vendor/plugins/.*?/)?#{ Regexp.escape(options[:input]) }/(.+\.handlebars)\z})
      end

      super(defaults.merge(options))
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def start
      run_all if options[:all_on_start]
    end


    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when stop has failed
    #
    # Compiles templates from app/views/jst to public/javascripts/jst
    def run_on_modifications(paths)
      paths = paths.map{ |path|
        prefix = path =~ %r{\Avendor/plugins/.*?/} ? $& : ''
        [prefix, path]
      }
      Parallel.each(paths, :in_threads => Parallel.processor_count) do |prefix, path|
        begin
          UI.info "Compiling: #{path}"
          HandlebarsTasks::Handlebars.compile_file path, "#{prefix}app/views/jst", "#{prefix}#{@options[:output]}"
        rescue Exception => e
          ::Guard::UI.error(e.to_s, :title => path.sub('app/views/jst/', ''), :image => :failed)
        end
      end
    end

    # Gets called when all files should be regenerated.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def run_all
      UI.info "Compiling all handlebars templates in #{@options[:input]} to #{@options[:output]}"
      FileUtils.rm_r @options[:output] if File.exist?(@options[:output])
      HandlebarsTasks::Handlebars.compile @options[:input], @options[:output]
      UI.info "Successfully compiled all handlebars templates in #{@options[:input]}"
    end


    # Called on file(s) deletions that the Guard watches.
    def run_on_removals(paths)
      paths.each do |file|
        javascript = file.sub(%r{\A#{Regexp.escape(@options[:input])}/(.*?)\.handlebars}, "#{@options[:output]}/\\1.js")
        UI.info "Removing: #{javascript}"
        File.delete(javascript) if File.exist?(javascript)
      end
    end

  end
end
