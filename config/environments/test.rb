if ENV['COVERAGE'] == "1"
  puts "Code Coverage enabled"
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.use_merging
  SimpleCov.merge_timeout(10000)

  SimpleCov.command_name "RSpec:#{Process.pid}#{ENV['TEST_ENV_NUMBER']}"
  SimpleCov.start do
    SimpleCov.at_exit {
      SimpleCov.result
      #SimpleCov.result.format! to get a coverage report without vendored_gems
    }
  end
else
  puts "Code coverage not enabled"
end

environment_configuration(defined?(config) && config) do |config|

  if ENV['BULLET'] == "1"
    puts "Bullet enabled"
    require 'bullet'

    config.after_initialize do
      Bullet.enable = true
      Bullet.bullet_logger = true
    end

  elsif ENV['BULLET_GEM'] == "1"
    puts "Bullet enabled"
    require 'bullet_instructure'

    config.after_initialize do
      Bullet.enable = true
      Bullet.bullet_logger = true
    end

  else
    puts "Bullet not enabled"
  end

  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  # in 1.9, whiny_nils causes a huge performance penalty on tests for some reason
  config.whiny_nils = false

  # Show full error reports and disable caching
  if CANVAS_RAILS2
    config.action_controller.consider_all_requests_local = true
  else
    config.consider_all_requests_local = true
  end
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
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }

  if CANVAS_RAILS2
    require_dependency 'nil_store'
    config.cache_store = NilStore.new
  else
    config.cache_store = :null_store
  end

  if CANVAS_RAILS2
    require_dependency 'canvas'

    # Raise an exception on bad mass assignment. Helps us catch these bugs before
    # they hit.
    Canvas.protected_attribute_error = :raise

    # Raise an exception on finder type mismatch or nil arguments. Helps us catch
    # these bugs before they hit.
    Canvas.dynamic_finder_nil_arguments_error = :raise
  else
    # Raise exceptions instead of rendering exception templates
    config.action_dispatch.show_exceptions = true

    # Print deprecation notices to the stderr
    config.active_support.deprecation = :stderr
  end
end
