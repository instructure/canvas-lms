class StatsTiming
  def initialize(app)
    @app = app
  end

  def call(env)
    result = nil
    ms = Benchmark.ms { result = @app.call(env) }

    path_parameters = env["action_controller.request.path_parameters"]
    controller = path_parameters.try(:[], :controller)
    action = path_parameters.try(:[], :action)
    account = env['canvas.domain_root_account']

    if controller && action
      Canvas::Statsd.timing("request.#{controller}.#{action}", ms)
      if account
        Canvas::Statsd.timing("account.#{account.global_id}.request.#{controller}.#{action}", ms)
      end
    end

    result
  end
end
