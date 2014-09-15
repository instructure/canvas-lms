# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
config = {
  :key           => '_normandy_session',
  :session_store => :encrypted_cookie_store,
  :secret        => (Setting.get_or_set("session_secret_key", SecureRandom.hex(64)) rescue SecureRandom.hex(64))
}.merge((ConfigFile.load("session_store") || {}).symbolize_keys)

# :expire_after is the "true" option, and :expires is a legacy option, but is applied
# to the cookie after :expire_after is, so by setting it to nil, we force the lesser
# of session expiration or expire_after for stores that have a way to expire sessions
# outside of the cookie (ActiveRecord::CookieStore+periodic job, MemCacheStore,
# RedisSessionStore, and EncryptedCookieStore)
config[:expire_after] ||= 1.day
config[:expires] = nil
config[:logger] = Rails.logger
session_store = config.delete(:session_store).to_sym

case session_store
when :mem_cache_store
  require 'memcache'
  config[:namespace] ||= config[:key]
  servers = config[:memcache_servers] || ConfigFile.load("memcache") || ['localhost:11211']
  config[:cache] ||= MemCache.new(servers, config)
when :redis_session_store
  Bundler.require 'redis'
  config[:key_prefix] ||= config[:key]
  config[:servers] ||= config[:redis_servers] if config[:redis_servers]
  redis_config = ConfigFile.load("redis")
  if redis_config
    config.reverse_merge!(redis_config.symbolize_keys)
  end
  config[:db] ||= config[:database]
end

CanvasRails::Application.config.session_store(session_store, config)
CanvasRails::Application.config.secret_token = config[:secret]