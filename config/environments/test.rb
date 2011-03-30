# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Inject our Rails 2.3.x broken cookie fix. See the whole sordid tale
# here:
# https://rails.lighthouseapp.com/projects/8994/tickets/4743-session-cookie-breaks-if-used-with-custom-cookie-in-rails-238
# and the unreleased fix on the 2.3 branch:
# https://github.com/rails/rails/commit/e0eb8e9c65ededce64169948d4dd51b0079cdd10
# and this temporary fix is based off:
# https://gist.github.com/431811
# We only need this in the test environment, because when sending the
# header to the browser, the cookies are converted to a string and the
# problem is avoided. Only tests manually inspect the cookie response
# header in ways that show the breakage.
config.after_initialize do
  require(Rails.root + 'spec/rack_rails_cookie_header_hack')
  ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, RackRailsCookieHeaderHack)
end

# Rails can't correctly set :protocol => 'https' as part of a controller spec,
# so we just turn the ssl check off.
SslRequirement.disable_ssl_check = true

# eval <env>-local.rb if it exists
Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }
