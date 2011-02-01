class RackRailsCookieHeaderHack
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    if headers['Set-Cookie'].is_a?(Array)
      headers['Set-Cookie'].collect! { |h| h.strip }
    end
    [status, headers, body]
  end
end
