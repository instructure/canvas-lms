# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Really do care if the message wasn't sent.
config.action_mailer.raise_delivery_errors = true

# Raise an exception on bad mass assignment. Helps us catch these bugs before
# they hit.
Canvas.protected_attribute_error = :raise

# Raise an exception on finder type mismatch or nil arguments. Helps us catch
# these bugs before they hit.
Canvas.dynamic_finder_nil_arguments_error = :raise
Canvas.dynamic_finder_type_cast_error = :raise

# eval <env>-local.rb if it exists
Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }

# allow debugging only in development environment by default
require "ruby-debug"
