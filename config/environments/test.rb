# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
if RUBY_VERSION >= "1.9."
  # in 1.9, whiny_nils causes a huge performance penalty on tests for some reason
  config.whiny_nils = false
else
  config.whiny_nils = true
end

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# run rake js:build to build the optimized JS if set to true
# ENV['USE_OPTIMIZED_JS']                              = 'true'

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Raise an exception on bad mass assignment. Helps us catch these bugs before
# they hit.
Canvas.protected_attribute_error = :raise

# Raise an exception on finder type mismatch or nil arguments. Helps us catch
# these bugs before they hit.
Canvas.dynamic_finder_nil_arguments_error = :raise

# eval <env>-local.rb if it exists
Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }

config.cache_store = :nil_store
