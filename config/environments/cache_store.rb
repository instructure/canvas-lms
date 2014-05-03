# this file is evaluated during config/environments/{development,production}.rb
#
# this needs to happen during environment config, rather than in a
# config/initializer/*, to allow Rails' full initialization of the cache to
# take place, including middleware inserts and such.
#
# (autoloading is not available yet, so we need to manually require necessary
# classes)
#
require_dependency 'canvas'
if CANVAS_RAILS2
  # we want this code to run as if it were in an initializer('something',
  # before: "initialize_cache") {} block, but rails2 doesn't let us do fine
  # grained initializers. fortunately, this file is loaded during the
  # load_environments step that comes after the require_frameworks step and
  # before the initialize_cache step of boot. as long as we force
  # ActionController::Dispatcher to be loaded (it's already been autoloaded,
  # but preload_frameworks hasn't run yet), so that its middleware gets set up,
  # we should be set.
  ActionController::Dispatcher

  # instantiate all cache stores and put them back so the instances are
  # persisted over calls to Canvas.full_cache_store_config. insert
  # middlewares similarly to Rails' default initialize_cache initializer, but
  # for each value.
  cache_stores = Canvas.cache_stores
  cache_stores.keys.each do |env|
    cache_stores[env] = ActiveSupport::Cache.lookup_store(cache_stores[env])
    if cache_stores[env].respond_to?(:middleware)
      config.middleware.insert_before("ActionController::Failsafe", cache_stores[env].middleware)
    end
  end

  # now set RAILS_CACHE so that Rails' default initialize_cache is a no-op.
  silence_warnings { Object.const_set "RAILS_CACHE", cache_stores[Rails.env] }
else
  # just set to the map of configs; switchman will handle the stuff from the
  # rails2 branch above in an initializer.
  config.cache_store = Canvas.cache_stores
end
