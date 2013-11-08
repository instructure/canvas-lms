environment_configuration(defined?(config) && config) do |config|
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  if CANVAS_RAILS2
    config.action_controller.consider_all_requests_local = true
  else
    config.consider_all_requests_local = true
  end
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # run rake js:build to build the optimized JS if set to true
  # ENV['USE_OPTIMIZED_JS']                            = 'true'

  # Really do care if the message wasn't sent.
  config.action_mailer.raise_delivery_errors = true

  # initialize cache store
  # this needs to happen in each environment config file, rather than a
  # config/initializer/* file, to allow Rails' full initialization of the cache
  # to take place, including middleware inserts and such.
  require_dependency 'canvas'
  config.cache_store = Canvas.cache_store_config

  # eval <env>-local.rb if it exists
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }

  # allow debugging only in development environment by default
  # ruby-debug is currently broken in 1.9.3
  #
  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.
  unless ENV['DISABLE_RUBY_DEBUGGING']
    require "debugger"
  end

  if CANVAS_RAILS2
    config.to_prepare do
      # Raise an exception on bad mass assignment. Helps us catch these bugs before
      # they hit.
      Canvas.protected_attribute_error = :raise

      # Raise an exception on finder type mismatch or nil arguments. Helps us catch
      # these bugs before they hit.
      Canvas.dynamic_finder_nil_arguments_error = :raise
    end
  else
    # Print deprecation notices to the Rails logger
    config.active_support.deprecation = :log

    # Only use best-standards-support built into browsers
    config.action_dispatch.best_standards_support = :builtin
  end
end
