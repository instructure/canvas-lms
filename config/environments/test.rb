environment_configuration(defined?(config) && config) do |config|
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
  if Rails.version < "3.0"
    config.action_controller.consider_all_requests_local = true
  else
    config.consider_all_requests_local = true
  end
  config.action_controller.perform_caching = false

  # run rake js:build to build the optimized JS if set to true
  # ENV['USE_OPTIMIZED_JS']                            = 'true'

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  #hairtrigger parallelized runtime race conditions
  config.active_record.schema_format = :sql

  # eval <env>-local.rb if it exists
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }

  # XXX: Rails3 NullStore wasn't added until Rails 3.2, but can replace our custom NilStore
  #config.cache_store = :null
  require_dependency 'nil_store'
  config.cache_store = NilStore.new

  if Rails.version < "3.0"
    # Raise an exception on bad mass assignment. Helps us catch these bugs before
    # they hit.
    Canvas.protected_attribute_error = :raise

    # Raise an exception on finder type mismatch or nil arguments. Helps us catch
    # these bugs before they hit.
    Canvas.dynamic_finder_nil_arguments_error = :raise
  else
    # Raise exceptions instead of rendering exception templates
    config.action_dispatch.show_exceptions = false

    # Print deprecation notices to the stderr
    config.active_support.deprecation = :stderr
  end
end
