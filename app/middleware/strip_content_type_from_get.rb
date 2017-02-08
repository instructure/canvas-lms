class StripContentTypeFromGet 
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['REQUEST_METHOD'] == "GET" && !env['CONTENT_TYPE'].nil?
      if /^\/api\/v1\/files\/[0-9]+\/create_success$/ =~ env['REQUEST_PATH']
        env['CONTENT_TYPE'] = nil
      end
    end
    @app.call(env)
  end
end
