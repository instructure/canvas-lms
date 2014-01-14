class SessionsTimeout
  def initialize(app)
    @app = app
  end

  # When loading an account, set the expire_after key if they have set up session
  # timeouts in the plugin settings. :expire_after is relative to Time.now and 
  # should be a Fixnum. This will work it's way up to encrypted_cookie_store.rb 
  # where the session's expire time is determined. EncryptedCookieStore is in a gem.
  def call(env)
    session_option_key = EncryptedCookieStore::EXPIRE_AFTER_KEY
    sessions_settings = Canvas::Plugin.find('sessions').settings
    sessions_timeout = 1.day # defaults to 1 day (in seconds)

    # Grab settings, convert them to seconds.(everything is converted down to seconds)
    if sessions_settings && sessions_settings["session_timeout"].present?
      sessions_timeout = sessions_settings["session_timeout"].to_f.minutes
    end

    env[session_option_key] = sessions_timeout

    @app.call(env)
  end
end
