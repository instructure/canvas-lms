# remove after switch to Rails 4
class Rails3FlashShim
  def initialize(app)
    @app = app
  end

  def call(env)
    if (session = env['rack.session']) && (flash = session['flash'])
      if flash.is_a?(Hash)
        session['flash'] = nil
      end
    end

    @app.call(env)
  end
end