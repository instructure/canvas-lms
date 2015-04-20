Rails.configuration.to_prepare do
  LiveEvents.logger = Rails.logger
  LiveEvents.cache = Rails.cache
  LiveEvents.statsd = CanvasStatsd::Statsd
  LiveEvents.max_queue_size = -> { Setting.get('live_events_max_queue_size', 1000).to_i }
  LiveEvents.plugin_settings = -> { Canvas::Plugin.find(:live_events) }
end

