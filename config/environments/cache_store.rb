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
config.cache_store = Canvas.cache_stores
