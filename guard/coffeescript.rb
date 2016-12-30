#
# Copyright (c) 2010 - 2011 Michael Kessler
#   with modifications by Instructure Inc, 2011
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'guard'
require 'guard/plugin'
require 'guard/watcher'
require 'coffee_script'

module Guard

  class CoffeeScript < Plugin

    module Formatter
      class << self
        def info(message, options = {}); ::Guard::UI.info(message, options); end

        def error(message, options = {}); ::Guard::UI.error(color(message, ';31'), options); end

        def success(message, options = {}); ::Guard::UI.info(color(message, ';32'), options); end

        def notify(message, options = {}); ::Guard::Notifier.notify(message, options); end
        private
        def color(text, color_code); ::Guard::UI.send(:color_enabled?) ? "\e[0#{ color_code }m#{ text }\e[0m" : text; end
      end
    end

    module Runner
      class << self

        def run(files, watchers, options = { })
          notify_start(files, options)
          changed_files, errors = partition_by_plugin(files) do |prefix, plugin_files|
            compile_files(plugin_files, watchers, options.merge(:output => "#{prefix}#{options[:output]}"))
          end
          notify_result(changed_files, errors, options)
          [changed_files, errors.empty?]
        end

        private

        def partition_by_plugin(files, &block)
          groupings = files.inject({}) { |hash, file|
            prefix = file =~ %r{\Agems/plugins/.*?/} ? $& : ''
            hash[prefix] ||= []
            hash[prefix] << file
            hash
          }
          groupings.map(&block).inject([[], []]) { |ary, ret|
            ary[0].concat ret[0]
            ary[1].concat ret[1]
            ary
          }
        end

        def notify_start(files, options)
          message = options[:message] || (options[:noop] ? 'Verify ' : 'Compile ') + files.join(', ')
          Formatter.info(message, :reset => true)
        end

        require 'parallel'
        require 'lib/canvas/coffee_script'
        def compile_files(files, watchers, options)
          errors        = []
          changed_files = []
          directories   = detect_nested_directories(watchers, files, options)

          if Canvas::CoffeeScript.coffee_script_binary_is_available?
            Parallel.each(directories.map, :in_threads => Parallel.processor_count) do |(directory, scripts)|
              FileUtils.mkdir_p(File.expand_path(directory)) if !File.directory?(directory) && !options[:noop]
              system('coffee', '-c', '-o', directory, *scripts)
              if $?.exitstatus != 0
                Formatter.error("Unable to compile coffeescripts in #{directory}")
              else
                changed_files.concat(scripts.map { |script| File.join(directory, File.basename(script.gsub(/(js\.coffee|coffee)$/, 'js'))) })
              end
            end
          else
            directories.each do |directory, scripts|
              Parallel.each(scripts, :in_threads => Parallel.processor_count) do |file|
                begin
                  content = compile(file, options)
                  changed_files << write_javascript_file(content, file, directory, options)
                rescue Exception => e
                  error_message = file + ': ' + e.message.to_s
                  errors << error_message
                  Formatter.error(error_message)
                end
              end
            end
          end

          [changed_files.compact, errors]
        end

        def compile(file, options)
          file_options = options_for_file(file, options)
          ::CoffeeScript.compile(File.read(file), file_options)
        end

        def options_for_file(file, options)
          return options unless options[:bare].respond_to? :include?

          file_options        = options.clone
          filename            = file[/([^\/]*)\.coffee/]
          file_options[:bare] = file_options[:bare].include?(filename)

          file_options
        end

        def write_javascript_file(content, file, directory, options)
          FileUtils.mkdir_p(File.expand_path(directory)) if !File.directory?(directory) && !options[:noop]
          filename = File.join(directory, File.basename(file.gsub(/(js\.coffee|coffee)$/, 'js')))
          File.open(File.expand_path(filename), 'w') { |f| f.write(content) } if !options[:noop]

          filename
        end

        def detect_nested_directories(watchers, files, options)
          return { options[:output] => files } if options[:shallow]

          directories = { }

          watchers.product(files).each do |watcher, file|
            if matches = watcher.pattern.match(file)
              target = matches[1] ? File.join(options[:output], File.dirname(matches[1])).gsub(/\/\.$/, '') : options[:output]
              if directories[target]
                directories[target] << file
              else
                directories[target] = [file]
              end
            end
          end

          directories
        end

        def notify_result(changed_files, errors, options = { })
          if !errors.empty?
            Formatter.notify(errors.join("\n"), :title => 'CoffeeScript results', :image => :failed, :priority => 2)
          elsif !options[:hide_success]
            message = "Successfully #{ options[:noop] ? 'verified' : 'generated' } #{ changed_files.join(', ') }"
            Formatter.success(message)
            Formatter.notify(message, :title => 'CoffeeScript results')
          end
        end

      end
    end

    DEFAULT_OPTIONS = {
        :bare         => false,
        :shallow      => false,
        :hide_success => false,
        :noop         => false,
        :all_on_start => false
    }

    def initialize(options = {})
      options[:watchers] ||= []
      defaults = DEFAULT_OPTIONS.clone

      if options[:input]
        defaults.merge!({ :output => options[:input] })
        options[:watchers] << ::Guard::Watcher.new(%r{\A(?:gems/plugins/.*?/)?#{ Regexp.escape(options.delete(:input)) }/(.+\.coffee)\z})
      end

      super(defaults.merge(options))
    end

    def start
      run_all if options[:all_on_start]
    end

    def run_all
      run_on_modifications(Watcher.match_files(self, Dir.glob(File.join('**/*/**', '*.coffee'))))
    end

    def run_on_modifications(paths)
      changed_files, success = Runner.run(clean(paths), watchers, options)

      throw :task_has_failed unless success
    end

    def run_on_removals(paths)
      clean(paths).each do |file|
        javascript = file.gsub(/(js\.coffee|coffee)$/, 'js')
        File.remove(javascript) if File.exist?(javascript)
      end
    end

    private

    def clean(paths)
      paths.uniq!
      paths.compact!
      paths.select { |p| p =~ /.coffee$/ && File.exist?(p) }
    end
  end
end
