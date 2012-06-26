namespace :js do

  desc 'test javascript specs with PhantomJS'
  task :test do
    quick = ENV["quick"] && ENV["quick"] == "true"
    unless quick
      puts "--> do rake js:test quick=true to skip generating compiled coffeescript and handlebars."
      Rake::Task['js:generate'].invoke
    end
    puts "--> executing phantomjs tests"

    require 'canvas/require_js'
    require 'erubis'
    output = Erubis::Eruby.new(File.read("#{Rails.root}/spec/javascripts/runner.html.erb")).
      result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/spec/javascripts/runner.html", 'w') { |f| f.write(output) }

    phantomjs_output = `phantomjs spec/javascripts/support/qunit/test.js file:///#{Dir.pwd}/spec/javascripts/runner.html`
    exit_status = $?.exitstatus
    puts phantomjs_output
    raise "PhantomJS tests failed" if exit_status != 0
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
      out.write CoffeeScript.compile(File.open(coffee_file))
    end
  end

  desc "generates compiled coffeescript and handlebars templates"
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
      puts "--> Pre-compiling handlebars templates"
      handlebars_time = Benchmark.realtime { Rake::Task['jst:compile'].invoke }
      puts "--> Pre-compiling handlebars templates finished in #{handlebars_time}"
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
            system("coffee -c -o #{destination} #{dir}/*.coffee")
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

end
