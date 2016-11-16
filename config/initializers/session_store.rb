# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
config = {
  :key           => '_normandy_session',
  :secret        => (Setting.get_or_set("session_secret_key", SecureRandom.hex(64)) rescue SecureRandom.hex(64))
}.merge((ConfigFile.load("session_store") || {}).symbolize_keys)

# :expire_after is the "true" option, and :expires is a legacy option, but is applied
# to the cookie after :expire_after is, so by setting it to nil, we force the lesser
# of session expiration or expire_after
config[:expire_after] ||= 1.day
config[:expires] = nil
config[:logger] = Rails.logger

Autoextend.hook(:EncryptedCookieStore, :SessionsTimeout)

CanvasRails::Application.config.session_store(:encrypted_cookie_store, config)
CanvasRails::Application.config.secret_token = config[:secret]
