module SessionsTimeout

  SESSION_OPTIONS_KEY = if CANVAS_RAILS4_2
                          Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY
                        else
                          Rack::RACK_SESSION_OPTIONS
                        end

  # When loading an account, set the expire_after key if they have set up session
  # timeouts in the plugin settings. :expire_after is relative to Time.now and
  # should be a Integer. This will work it's way up to encrypted_cookie_store.rb
  # where the session's expire time is determined. EncryptedCookieStore is in a gem.
  def get_cookie(req)
    sessions_settings = Canvas::Plugin.find('sessions').settings

    # Grab settings, convert them to seconds.(everything is converted down to seconds)
    if sessions_settings && sessions_settings["session_timeout"].present?
      expire_after = sessions_settings["session_timeout"].to_f.minutes
      if CANVAS_RAILS4_2
        req[SESSION_OPTIONS_KEY][:expire_after] = expire_after
      else
        req.get_header(SESSION_OPTIONS_KEY)[:expire_after] = expire_after
      end
    end

    super
  end
end
