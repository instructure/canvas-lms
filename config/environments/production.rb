environment_configuration(defined?(config) && config) do |config|
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  if Rails.version < "3.0"
    config.action_controller.consider_all_requests_local = true
  else
    config.consider_all_requests_local = true
  end
  config.action_controller.perform_caching = true

  # run rake js:build to build the optimized JS if set to true
  ENV['USE_OPTIMIZED_JS']                              = "true"

  # initialize cache store
  # this needs to happen in each environment config file, rather than a
  # config/initializer/* file, to allow Rails' full initialization of the cache
  # to take place, including middleware inserts and such.
  require_dependency 'canvas'
  config.cache_store = Canvas.cache_store_config

  # eval <env>-local.rb if it exists
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read) }

  if Rails.version >= "3.0"
    # Specifies the header that your server uses for sending files
    config.action_dispatch.x_sendfile_header = "X-Sendfile"

    # For nginx:
    # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

    # If you have no front-end server that supports something like X-Sendfile,
    # just comment this out and Rails will serve the files

    # Disable Rails's static asset server
    # In production, Apache or nginx will already do this
    config.serve_static_assets = false

    # Enable serving of images, stylesheets, and javascripts from an asset server
    # config.action_controller.asset_host = "http://assets.example.com"

    # Disable delivery errors, bad email addresses will be ignored
    # config.action_mailer.raise_delivery_errors = false

    # Enable threaded mode
    # config.threadsafe!

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation can not be found)
    # config.i18n.fallbacks = true

    # Send deprecation notices to registered listeners
    config.active_support.deprecation = :notify
  end
end
