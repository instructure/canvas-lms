class StatsTiming
  def initialize(app)
    @app = app
  end

  def call(env)
    result = nil
    ms = Benchmark.ms { result = @app.call(env) }
    path_parameters = env["action_dispatch.request.path_parameters"]
    controller = path_parameters.try(:[], :controller)
    action = path_parameters.try(:[], :action)

    if controller && action
      CanvasStatsd::Statsd.timing("request.#{controller}.#{action}", ms)
    end

    result
  end
end
