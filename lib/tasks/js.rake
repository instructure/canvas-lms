namespace :js do

  desc 'test javascript specs with PhantomJS'
  task :test do
    quick = ENV["quick"] && ENV["quick"] == "true"
    unless quick
      puts "--> do rake js:test quick=true to skip generating compiled coffeescript and handlebars."
      Rake::Task['js:generate'].invoke
    end
    puts "--> executing phantomjs tests"
    phantomjs_output = `phantomjs spec/javascripts/support/qunit/test.js spec/javascripts/runner.html`
    exit_status = $?.exitstatus
    puts phantomjs_output
    raise "PhantomJS tests failed" if exit_status != 0
  end

  def compile_coffescript(coffee_file)
    destination = coffee_file.sub('app/coffeescripts', 'public/javascripts/compiled').
                              sub('spec/coffeescripts', 'spec/javascripts').
                              sub(%r{/javascripts/compiled/plugins/([^/]+)/}, '/plugins/\\1/javascripts/compiled/').
                              sub(%r{\.coffee$}, '.js')
    FileUtils.mkdir_p(File.dirname(destination))
    File.open(destination, 'wb') do |out|
      out.write CoffeeScript.compile(File.open(coffee_file))
    end
  end

  desc "generates compiled coffeescript and handlebars templates"
  task :generate do
    require 'config/initializers/plugin_symlinks'
    require 'coffee-script'
    require 'fileutils'

    # clear out all the files in case there are any old compiled versions of
    # files that don't map to any source file anymore
    FileUtils.rm_rf('public/javascripts/compiled')
    FileUtils.rm_rf('public/javascripts/jst')
    FileUtils.rm_rf('public/plugins/*/javascripts/compiled')
    FileUtils.rm_rf('public/plugins/*/javascripts/jst')

    puts "--> Pre-compiling all handlebars templates"
    Rake::Task['jst:compile'].invoke
    puts "--> Compiling all Coffeescript"
    Dir[Rails.root+'spec/coffeescripts/{,plugins/*/}**/*.coffee'].each do |file|
      compile_coffescript file
    end
    Dir[Rails.root+'app/coffeescripts/{,plugins/*/}**/*.coffee'].each do |file|
      compile_coffescript file
    end
  end

  desc "optimize and build js for production"
  task :build do
    require 'config/initializers/plugin_symlinks'

    puts "--> Optimizing canvas-lms"
    output = `node #{Rails.root}/node_modules/requirejs/bin/r.js -o #{Rails.root}/config/build.js 2>&1`
    raise "Error running js:build: \n#{output}\nABORTING" if $?.exitstatus != 0

    Dir[Rails.root+'vendor/plugins/*/config/build.js'].each do |buildfile|
      plugin = buildfile.gsub(%r{.*/vendor/plugins/(.*)/config/build\.js}, '\\1')
      puts "--> Optimizing #{plugin} plugin"
      output = `node #{Rails.root}/node_modules/requirejs/bin/r.js -o #{buildfile} 2>&1`
      raise "Error running js:build: \n#{output}\nABORTING" if $?.exitstatus != 0
    end
  end

end
