if ENV['COVERAGE'] == "1"
  puts "Code Coverage enabled"
  begin
    require '../../spec/coverage.rb'
    CoverageTool.start("canvas")
  rescue LoadError => e
    puts "Error: #{e}"
  end
end

environment_configuration(defined?(config) && config) do |config|

  if ENV['BULLET_GEM']
    puts "Bullet Instructure enabled"

    config.after_initialize do
      Bullet.enable = true
      Bullet.bullet_logger = true
    end

  else
    puts "Bullet Instructure not enabled"
  end

  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  if CANVAS_RAILS3
    # Log error messages when you accidentally call methods on nil.
    # in 1.9, whiny_nils causes a huge performance penalty on tests for some reason
    config.whiny_nils = false
  end

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # run rake js:build to build the optimized JS if set to true
  # ENV['USE_OPTIMIZED_JS']                            = 'true'

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  #hairtrigger parallelized runtime race conditions
  config.active_record.schema_format = :sql

  # eval <env>-local.rb if it exists
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read, nil, localfile, 1) }

  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = true

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  unless CANVAS_RAILS3
    config.eager_load = false
  end
end
