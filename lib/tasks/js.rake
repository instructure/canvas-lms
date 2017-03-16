require 'json'
require_relative "../../config/initializers/webpack"

namespace :js do
  # ---------------- META TASKS ----------------
  # (add functionality as a separate task below)

  desc "Generates compiled coffeescript, handlebars templates and plugin extensions"
  task generate: %i[clean build_client_apps] do

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

    threads << Thread.new do
      coffee_time = Benchmark.realtime do
        Rake::Task['js:coffee'].invoke
      end
      puts "--> Compiling CoffeeScript finished in #{coffee_time}"
    end

    threads.each(&:join)
  end

  desc "Optimize and build js for production"
  task :build do
    Rake::Task['js:rjs_config'].invoke

    puts "--> Concatenating JavaScript bundles with r.js"
    time = Benchmark.realtime { Rake::Task['js:rjs_concat'].invoke }
    puts "--> Concatenated JavaScript bundles in #{time}"

    unless ENV["JS_BUILD_NO_UGLIFY"]
      puts "--> Compressing JavaScript with UglifyJS"
      time = Benchmark.realtime { Rake::Task['js:compress'].invoke }
      puts "--> Compressed JavaScript in #{time}"
    end
  end

  # --- TASKS ---

  desc "Generates plugin extension modules"
  task :generate_extensions do
    require 'canvas/require_js/plugin_extension'
    Canvas::RequireJs::PluginExtension.generate_all
  end

  desc "Build client_apps"
  task :build_client_apps do
    require 'config/initializers/client_app_symlinks'

    Dir.glob('./client_apps/*/').each do |app_dir|
      app_name = File.basename(app_dir)

      Dir.chdir(app_dir) do
        puts "Building client app '#{app_name}'"

        if File.exists?('./package.json')
          output = `yarn install || npm install` rescue `npm cache clean && npm install`
          unless $?.exitstatus == 0
            puts "INSTALL FAILURE:\n#{output}"
            raise "Package installation failure for client app #{app_name}"
          end
        end

        puts "\tRunning 'npm run build'..."
        output = `./script/build`
        unless $?.exitstatus == 0
          puts "BUILD FAILURE:\n#{output}"
          raise "Build script failed for client app #{app_name}"
        end

        puts "Client app '#{app_name}' was built successfully."
      end
    end

    maintain_client_app_symlinks
  end

  desc "Cleans build javascript files"
  task :clean do
    require 'config/initializers/plugin_symlinks'

    paths_to_remove = [
      Dir.glob('public/javascripts/{compiled,jst,jsx}'),
      Dir.glob('public/plugins/*/javascripts/{compiled,jst,jsx}'),
      'spec/javascripts/compiled',
      Dir.glob('spec/plugins/*/javascripts/compiled')
    ]
    FileUtils.rm_rf(paths_to_remove)
  end

  desc "Compile Coffeescript to JS"
  task :coffee do
    require 'coffee-script'
    require 'parallel'
    require 'canvas/coffee_script'

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
        destination = coffee_destination(file).sub(%r{\.coffee$}, '.js')
        FileUtils.mkdir_p(File.dirname(destination))
        File.open(destination, 'wb') do |out|
          File.open(file) do |cfile|
            out.write CoffeeScript.compile(cfile)
          end
        end
      end
    end
  end

  def coffee_destination(dir_or_file)
    dir_or_file.sub('app/coffeescripts', 'public/javascripts/compiled').
        sub('spec/coffeescripts', 'spec/javascripts/compiled').
        sub(%r{/javascripts/compiled/plugins/([^/]+)(/|$)}, '/plugins/\\1/javascripts/compiled\\2')
  end

  desc "Build webpack js"
  task :webpack do
    puts "this webpack rake task is going away. just run `yarn run webpack-production` or `yarn run webpack-development` directly."
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

  desc "Concatenate js bundles with r.js"
  task :rjs_concat do
    output = `node #{Rails.root}/node_modules/requirejs/bin/r.js -o #{Rails.root}/config/build.js 2>&1`
    raise "Error running js:rjs_concat: \n#{output}\nABORTING" if $?.exitstatus != 0
  end

  desc "Compress js with uglify"
  task :compress do
    output = `npm run compress 2>&1`
    raise "Error running js:compress: \n#{output}\nABORTING" if $?.exitstatus != 0
  end

  desc "Write config/build.js for r.js"
  task :rjs_config do
    require 'config/initializers/plugin_symlinks'
    require 'canvas/require_js'
    require 'erubis'

    output = Erubis::Eruby.new(File.read("#{Rails.root}/config/build.js.erb")).
        result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/config/build.js", 'w') { |f| f.write(output) }
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

    dirs.each do |source,dest|
      opts = Rails.env.development? ? "--source-maps inline" : ""
      msg = `node_modules/.bin/babel #{source} --out-dir #{dest} #{opts} 2>&1 >/dev/null`
      raise msg unless $?.success?
    end
  end

  desc "Ensure up-to-date node environment"
  task :npm_install do
    puts "node is: #{`node -v`.strip} (#{`which node`.strip})"
    raise 'error running yarn install' unless `yarn install || npm install`
  end

  desc "Run Gulp Rev, for fingerprinting assets"
  task :gulp_rev do
    raise "Error reving files" unless system('node_modules/.bin/gulp rev')
  end
end
