# Initialize canvas statsd configuration. See config/statsd.yml.example.

settings = Setting.from_config("statsd") || {}

Rails.configuration.to_prepare do
  CanvasStatsd.settings = settings
end
