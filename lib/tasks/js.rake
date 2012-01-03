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
                              sub(%r{\.coffee$}, '.js')
    FileUtils.mkdir_p(File.dirname(destination))
    File.open(destination, 'wb') do |out|
      out.write CoffeeScript.compile(File.open(coffee_file))
    end
  end

  desc "generates compiled coffeescript and handlebars templates"
  task :generate do
    require 'coffee-script'
    require 'fileutils'
    puts "--> Pre-compiling all handlebars templates"
    Rake::Task['jst:compile'].invoke
    puts "--> Compiling all Coffeescript"
    Dir[Rails.root+'spec/coffeescripts/**/*.coffee'].each do |file|
      compile_coffescript file
    end
    Dir[Rails.root+'app/coffeescripts/**/*.coffee'].each do |file|
      compile_coffescript file
    end
  end

end
