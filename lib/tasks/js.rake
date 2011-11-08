namespace :js do

  desc 'test javascript specs with PhantomJS'
  task :test do
     exec("phantomjs spec/javascripts/support/qunit/test.js spec/javascripts/runner.html")
  end

end
