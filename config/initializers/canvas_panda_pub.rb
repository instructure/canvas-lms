Rails.configuration.to_prepare do
  CanvasPandaPub.logger = Rails.logger
  CanvasPandaPub.cache = Rails.cache
  CanvasPandaPub.plugin_settings = -> { Canvas::Plugin.find(:pandapub) }
  CanvasPandaPub.max_queue_size = -> { Setting.get('pandapub_max_queue_size', 1000).to_i }
  CanvasPandaPub.process_interval = -> { Setting.get('pandapub_process_interval_seconds', 1.0).to_f }
end
