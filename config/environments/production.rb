environment_configuration(defined?(config) && config) do |config|
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # run rake js:build to build the optimized JS if set to true
  ENV['USE_OPTIMIZED_JS']                              = "true"

  # initialize cache store. has to eval, not just require, so that it has
  # access to config.
  cache_store_rb = File.dirname(__FILE__) + "/cache_store.rb"
  eval(File.new(cache_store_rb).read, nil, cache_store_rb, 1)

  # Specifies the header that your web server uses for directly sending files
  # If you have mod_xsendfile enabled in apache:
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile'
  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_files = false

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

  # we use lots of db specific stuff - don't bother trying to dump to ruby
  # (it also takes forever)
  config.active_record.schema_format = :sql

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.eager_load = true

  # eval <env>-local.rb if it exists
  Dir[File.dirname(__FILE__) + "/" + File.basename(__FILE__, ".rb") + "-*.rb"].each { |localfile| eval(File.new(localfile).read, nil, localfile, 1) }
end
