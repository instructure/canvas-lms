require 'timeout'

namespace :js do

  task :dev do
    Rake::Task['js:generate_runner'].invoke
    exec('testem -f config/testem.yml')
  end

  desc 'generate QUnit runner file @ spec/javascripts/runner.html'
  task :generate_runner do
    #Rake::Task['js:generate'].invoke
    require 'canvas/require_js'
    require 'erubis'
    output = Erubis::Eruby.new(File.read("#{Rails.root}/spec/javascripts/runner.html.erb")).
      result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/spec/javascripts/runner.html", 'w') { |f| f.write(output) }
  end

  desc 'test javascript specs with PhantomJS'
  task :test do
    begin
      Timeout::timeout(300) do
        quick = ENV["quick"] && ENV["quick"] == "true"
        unless quick
          puts "--> do rake js:test quick=true to skip generating compiled coffeescript and handlebars."
          Rake::Task['js:generate'].invoke
        end
        puts "--> executing phantomjs tests"
        Rake::Task['js:generate_runner'].invoke
        phantomjs_output = `phantomjs spec/javascripts/support/qunit/test.js file:///#{Dir.pwd}/spec/javascripts/runner.html 2>&1`
        exit_status = $?.exitstatus
        puts phantomjs_output
        raise "PhantomJS tests failed" if exit_status != 0
      end
    rescue Timeout::Error
      raise "PhantomJS tests reached timeout!"
    end
  end

  def coffee_destination(dir_or_file)
    dir_or_file.sub('app/coffeescripts', 'public/javascripts/compiled').
                sub('spec/coffeescripts', 'spec/javascripts').
                sub(%r{/javascripts/compiled/plugins/([^/]+)(/|$)}, '/plugins/\\1/javascripts/compiled\\2')
  end

  def compile_coffeescript(coffee_file)
    destination = coffee_destination(coffee_file).sub(%r{\.coffee$}, '.js')
    FileUtils.mkdir_p(File.dirname(destination))
    File.open(destination, 'wb') do |out|
      File.open(coffee_file) do |cfile|
        out.write CoffeeScript.compile(cfile)
      end
    end
  end

  desc "generates plugin extension modules"
  task :generate_extensions do
    require 'canvas/require_js/plugin_extension'
    Canvas::RequireJs::PluginExtension.generate_all
  end

  desc "generates compiled coffeescript, handlebars templates and plugin extensions"
  task :generate do
    require 'config/initializers/plugin_symlinks'
    require 'fileutils'
    require 'canvas'
    require 'canvas/coffee_script'

    # clear out all the files in case there are any old compiled versions of
    # files that don't map to any source file anymore
    paths_to_remove = [
      'public/javascripts/compiled',
      'public/javascripts/jst',
      'public/plugins/*/javascripts/{compiled,javascripts/jst}'
    ] + Dir.glob('spec/javascripts/**/*Spec.js')
    FileUtils.rm_rf(paths_to_remove)

    threads = []
    threads << Thread.new do
      puts "--> Generating plugin extensions"
      extensions_time = Benchmark.realtime { Rake::Task['js:generate_extensions'].invoke }
      puts "--> Generating plugin extensions finished in #{extensions_time}"
    end

    threads << Thread.new do
      puts "--> Pre-compiling handlebars templates"
      handlebars_time = Benchmark.realtime { Rake::Task['jst:compile'].invoke }
      puts "--> Pre-compiling handlebars templates finished in #{handlebars_time}"
    end

    threads << Thread.new do
      puts "--> Pre-compiling ember handlebars templates"
      ember_handlebars_time = Benchmark.realtime { Rake::Task['jst:ember'].invoke }
      puts "--> Pre-compiling ember handlebars templates finished in #{ember_handlebars_time}"
    end

    threads << Thread.new do
      coffee_time = Benchmark.realtime do
        require 'coffee-script'

        if Canvas::CoffeeScript.coffee_script_binary_is_available?
          puts "--> Compiling CoffeeScript with 'coffee' binary"
          dirs = Dir[Rails.root+'{app,spec}/coffeescripts/{,plugins/*/}**/*.coffee'].
              map { |f| File.dirname(f) }.uniq
          Parallel.each(dirs, :in_threads => Parallel.processor_count) do |dir|
            destination = coffee_destination(dir)
            FileUtils.mkdir_p(destination)
            system("coffee -m -c -o #{destination} #{dir}/*.coffee")
            raise "Unable to compile coffeescripts in #{dir}" if $?.exitstatus != 0
          end
        else
          puts "--> Compiling CoffeeScript with coffee-script gem"
          files = Dir[Rails.root+'{app,spec}/coffeescripts/{,plugins/*/}**/*.coffee']
          Parallel.each(files, :in_threads => Parallel.processor_count) do |file|
            compile_coffeescript file
          end
        end
      end
      puts "--> Compiling CoffeeScript finished in #{coffee_time}"

      # can't be in own thread, needs coffeescript first
      puts "--> Creating ember app bundles"
      bundle_time = Benchmark.realtime { Rake::Task['js:bundle_ember_apps'].invoke }
      puts "--> Creating ember app bundles finished in #{bundle_time}"
    end

    threads.each(&:join)
  end

  desc "optimize and build js for production"
  task :build do
    require 'config/initializers/plugin_symlinks'
    require 'canvas/require_js'
    require 'erubis'

    output = Erubis::Eruby.new(File.read("#{Rails.root}/config/build.js.erb")).
      result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/config/build.js", 'w') { |f| f.write(output) }

    puts "--> Optimizing canvas-lms"
    optimize_time = Benchmark.realtime do
      output = `node #{Rails.root}/node_modules/requirejs/bin/r.js -o #{Rails.root}/config/build.js 2>&1`
      raise "Error running js:build: \n#{output}\nABORTING" if $?.exitstatus != 0
    end
    puts "--> Optimized canvas-lms in #{optimize_time}"
  end

  desc "creates ember app bundles"
  task :bundle_ember_apps do
    require 'lib/ember_bundle'
    Dir.entries('app/coffeescripts/ember').reject {|d| d.match(/^\./) || d == 'shared'}.each do |app|
      EmberBundle.new(app).build
    end
  end

end
