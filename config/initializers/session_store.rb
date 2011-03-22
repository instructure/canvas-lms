# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
config = {
  :key           => '_normandy_session',
  :session_store => :active_record_store,
  :secret        => (Setting.get_or_set("session_secret_key",
      ActiveSupport::SecureRandom.hex(64)) rescue ActiveSupport::SecureRandom.hex(64)),
}.merge((Setting.from_config("session_store") || {}).symbolize_keys)

session_store = config.delete(:session_store).to_sym

case session_store
when :mem_cache_store
  require 'memcache'
  config[:namespace] ||= config[:key]
  servers = config[:memcache_servers] || Setting.from_config("memcache") || ['localhost:11211']
  config[:cache] ||= MemCache.new(servers, config)
when :redis_session_store
  Bundler.require 'redis'
  config[:key_prefix] ||= config[:key]
  config[:servers] ||= config[:redis_servers] || Setting.from_config("redis")
end

ActionController::Base.session = config
ActionController::Base.session_store = session_store
