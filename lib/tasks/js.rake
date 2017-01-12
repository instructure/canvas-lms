require 'timeout'
require 'json'
require_relative "../../config/initializers/webpack"

namespace :js do

  desc 'run Karma as you develop, can use `rake js:dev <ember app name> <browser>`'
  task :dev do
    app = ARGV[1]
    app = nil if app == 'NA'
    #browsers = ARGV[2] || 'Firefox,Chrome,Safari'
    browsers = ARGV[2] || 'Chrome'
    if app
      ENV['JS_SPEC_MATCHER'] = matcher_for_ember_app app
      unless File.exists?("app/coffeescripts/ember/#{app}")
        puts "no app found at app/coffeescripts/ember/#{app}"
        exit
      end
    end
    build_runner
    exec("node_modules/.bin/karma start --browsers #{browsers}")
  end

  def matcher_for_ember_app app_name
    "**/#{app_name}/**/*.spec.js"
  end

  desc 'generate QUnit runner file @ spec/javascripts/runner.html'
  task :generate_runner do
    build_runner
  end

  def build_runner
    require 'canvas/require_js'
    require 'erubis'
    output = Erubis::Eruby.new(File.read("#{Rails.root}/spec/javascripts/runner.html.erb")).
        result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/spec/javascripts/runner.html", 'w') { |f| f.write(output) }
    build_requirejs_config
  end

  def generate_prng
    if ENV["seed"]
      seed = ENV["seed"].to_i
    else
      srand
      seed = rand(1 << 20)
    end
    puts "--> randomized with seed #{seed}"
    Random.new(seed)
  end

  def build_requirejs_config
    require 'canvas/require_js'
    require 'erubis'
    output = Erubis::Eruby.new(File.read("#{Rails.root}/spec/javascripts/requirejs_config.js.erb")).
        result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/spec/javascripts/requirejs_config.js", 'w') { |f| f.write(output) }

    matcher = Canvas::RequireJs.matcher
    tests = Dir[
      "public/javascripts/*[!bower]/#{matcher}",
      "spec/javascripts/compiled/#{matcher}",
      "spec/plugins/*/javascripts/compiled/#{matcher}"
    ].map{ |file| file.sub(/\.js$/, '').sub(/public\/javascripts\//, '') }
    File.open("#{Rails.root}/spec/javascripts/tests.js", 'w') { |f|
      f.write("window.__TESTS__ = #{JSON.pretty_generate(tests.shuffle(random: generate_prng))}")
    }
  end

  desc 'test javascript specs with Karma'
  task :test, :reporter do |task, args|
    reporter = args[:reporter]
    if CANVAS_WEBPACK
      Rake::Task['i18n:generate_js'].invoke
      webpack_test_dir = Rails.root + "spec/javascripts/webpack"
      FileUtils.rm_rf(webpack_test_dir)
      puts "--> Bundling tests for ember apps"
      `npm run webpack-test-ember`
      puts "--> Running tests for ember apps"
      test_suite(reporter)
      FileUtils.rm_rf(webpack_test_dir)
      puts "--> Bundling tests for canvas proper"
      `npm run webpack-test`
      puts "--> Running tests for canvas proper"
      test_suite(reporter)
    else
      require 'canvas/require_js'

      # run test for each ember app individually
      matcher = ENV['JS_SPEC_MATCHER']

      if matcher
        puts "--> Matcher: #{matcher}"
      end

      if !matcher || matcher.to_s =~ %r{app/coffeescripts/ember}
        ignored_embers = ['shared','modules'] #,'quizzes','screenreader_gradebook'
        Dir.entries('app/coffeescripts/ember').reject { |d|
          d.match(/^\./) || ignored_embers.include?(d)
        }.each do |ember_app|
          puts "--> Running tests for '#{ember_app}' ember app"
          Canvas::RequireJs.matcher = matcher_for_ember_app ember_app
          test_suite(reporter)
        end
      end

      # run test for non-ember apps
      Canvas::RequireJs.matcher = nil
      test_suite(reporter)
    end
  end

  def test_suite(reporter=nil)
    if test_js_with_timeout(300,reporter) != 0 && !ENV['JS_SPEC_MATCHER'] && ENV['retry'] != 'false'
      puts "--> Karma tests failed." # retrying karma...
      raise "Karma tests failed on second attempt." if test_js_with_timeout(400,reporter) != 0
    end
  end

  def test_js_with_timeout(timeout,reporter)
    require 'canvas/require_js'
    begin
      Timeout::timeout(timeout) do
        quick = ENV["quick"] && ENV["quick"] == "true"
        unless quick
          puts "--> do rake js:test quick=true to skip generating compiled coffeescript and handlebars."
          Rake::Task['js:generate'].invoke
        end
        puts "--> executing browser tests with Karma"
        build_runner
        system "./node_modules/karma/bin/karma start --browsers Chrome --single-run --reporters progress,#{reporter}"

        if $?.exitstatus != 0
          puts 'some specs failed'
          result = 1
        else
          result = 0
        end
        return result
      end
    rescue Timeout::Error
      puts "Karma tests reached timeout!"
    end
  end

  def coffee_destination(dir_or_file)
    dir_or_file.sub('app/coffeescripts', 'public/javascripts/compiled').
        sub('spec/coffeescripts', 'spec/javascripts/compiled').
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

  task :build_client_apps do
    require 'config/initializers/client_app_symlinks'

    Dir.glob('./client_apps/*/').each do |app_dir|
      app_name = File.basename(app_dir)

      Dir.chdir(app_dir) do
        puts "Building client app '#{app_name}'"

        if File.exists?('./package.json')
          puts "\tRunning 'npm install'..."
          output = `npm install` rescue `npm cache clean && npm install`
          unless $?.exitstatus == 0
            puts <<-MESSAGE
            -------------------------------------------------------------------
            INSTALL FAILURE:
            #{output}
            -------------------------------------------------------------------
            MESSAGE

            raise "Package installation failure for client app #{app_name}"
          end
        end

        begin
          puts "\tRunning 'npm run build'..."
          output = `./script/build`
          unless $?.exitstatus == 0
            puts <<-MESSAGE
            -------------------------------------------------------------------
            BUILD FAILURE:
            #{output}
            -------------------------------------------------------------------
            MESSAGE

            raise "Build script failed for client app #{app_name}"
          end
        end

        puts "Client app '#{app_name}' was built successfully."
      end
    end

    maintain_client_app_symlinks
  end

  desc "generates compiled coffeescript, handlebars templates and plugin extensions"
  task :generate do
    require 'config/initializers/plugin_symlinks'
    require 'config/initializers/client_app_symlinks'
    require 'fileutils'
    require 'canvas'
    require 'canvas/coffee_script'

    # clear out all the files in case there are any old compiled versions of
    # files that don't map to any source file anymore
    paths_to_remove = [
      Dir.glob('public/javascripts/{compiled,jst,jsx}'),
      Dir.glob('public/plugins/*/javascripts/{compiled,jst,jsx}'),
      'spec/javascripts/compiled',
      Dir.glob('spec/plugins/*/javascripts/compiled')
    ]
    FileUtils.rm_rf(paths_to_remove)

    Rake::Task['js:build_client_apps'].invoke

    threads = []
    threads << Thread.new do
      puts "--> Generating plugin extensions"
      extensions_time = Benchmark.realtime { Rake::Task['js:generate_extensions'].invoke }
      puts "--> Generating plugin extensions finished in #{extensions_time}"
    end

    threads << Thread.new do
      puts "--> Compiling React JSX"
      jsx_time = Benchmark.realtime { Rake::Task['js:jsx'].invoke }
      puts "--> Compiling React JSX finished in #{jsx_time}"
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

    # can't be in own thread, needs to happen before coffeescript
    puts "--> Creating ember app bundles"
    bundle_time = Benchmark.realtime { Rake::Task['js:bundle_ember_apps'].invoke }
    puts "--> Creating ember app bundles finished in #{bundle_time}"

    threads << Thread.new do
      coffee_time = Benchmark.realtime do
        require 'coffee-script'
        require 'parallel'

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

  desc "build webpack js"
  task :webpack do
    if CANVAS_WEBPACK
      if ENV['RAILS_ENV'] == 'production' || ENV['USE_OPTIMIZED_JS'] == 'true' || ENV['USE_OPTIMIZED_JS'] == 'True'
        puts "--> Building PRODUCTION webpack bundles"
        `npm run webpack-production`
      else
        puts "--> Building DEVELOPMENT webpack bundles"
        `npm run webpack-development`
      end
      raise "Error running js:webpack: \nABORTING" if $?.exitstatus != 0
    end
  end

  desc "optimize and build js for production"
  task :build do
    require 'config/initializers/plugin_symlinks'
    require 'canvas/require_js'
    require 'erubis'

    output = Erubis::Eruby.new(File.read("#{Rails.root}/config/build.js.erb")).
        result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/config/build.js", 'w') { |f| f.write(output) }

    puts "--> Concatenating JavaScript bundles with r.js"
    optimize_time = Benchmark.realtime do
      output = `node #{Rails.root}/node_modules/requirejs/bin/r.js -o #{Rails.root}/config/build.js 2>&1`
      raise "Error running js:build: \n#{output}\nABORTING" if $?.exitstatus != 0
    end
    puts "--> Concatenated JavaScript bundles in #{optimize_time}"

    unless ENV["JS_BUILD_NO_UGLIFY"]
      puts "--> Compressing JavaScript with UglifyJS"
      optimize_time = Benchmark.realtime do
        output = `npm run compress 2>&1`
        raise "Error running js:build: \n#{output}\nABORTING" if $?.exitstatus != 0
      end
      puts "--> Compressed JavaScript in #{optimize_time}"
    end
  end

  desc "Compile React JSX to JS"
  task :jsx do
    # Get the canvas-lms jsx and specs to compile
    dirs = [["#{Rails.root}/app/jsx", "#{Rails.root}/public/javascripts/jsx"],
            ["#{Rails.root}/spec/javascripts/jsx", "#{Rails.root}/spec/javascripts/compiled"]]
    # Get files that need compilation in plugins
    plugin_jsx_dirs = Dir.glob("#{Rails.root}/gems/plugins/*/**/jsx")
    plugin_jsx_dirs.each do |directory|
      plugin_name = directory.match(/gems\/plugins\/([^\/]+)\//)[1]
      destination = "#{Rails.root}/public/javascripts/plugins/#{plugin_name}/compiled/jsx"
      FileUtils.mkdir_p(destination)
      dirs << [directory, destination]
    end

    dirs.each { |source,dest|
      if Rails.env == 'development'
        msg = `node_modules/.bin/babel #{source} --out-dir #{dest} --source-maps inline 2>&1 >/dev/null`
      else
        msg = `node_modules/.bin/babel #{source} --out-dir #{dest} 2>&1 >/dev/null`
      end

      unless $?.success?
        raise msg
      end
    }
  end

  desc "creates ember app bundles"
  task :bundle_ember_apps do
    require 'lib/ember_bundle'
    Dir.entries('app/coffeescripts/ember').reject { |d| d.match(/^\./) || d == 'shared' }.each do |app|
      EmberBundle.new(app).build
    end
  end
end
