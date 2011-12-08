namespace :js do

  desc 'test javascript specs with PhantomJS'
  task :test do
    quick = ENV["quick"] && ENV["quick"] == "true"
    unless quick
      puts "--> Recompiling everything in spec/coffeescripts, do rake js:test quick=true to skip this step."
      require 'coffee-script'
      require 'fileutils'
      Dir[Rails.root+'spec/coffeescripts/**/*.coffee'].each do |coffee|
        destination = coffee.sub('spec/coffeescripts', 'spec/javascripts').sub(%r{\.coffee$}, '.js')
        FileUtils.mkdir_p(File.dirname(destination))
        File.open(destination, 'wb') { |out| out.write CoffeeScript.compile(File.open(coffee)) }
      end
    end

    puts "--> executing phantomjs tests"
    phantomjs_output = `phantomjs spec/javascripts/support/qunit/test.js spec/javascripts/runner.html`
    exit_status = $?.exitstatus
    puts phantomjs_output
    raise "PhantomJS tests failed" if exit_status != 0

  end

end
