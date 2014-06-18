# Initialize canvas statsd configuration. See config/statsd.yml.example.

settings = ConfigFile.load("statsd") || {}

Rails.configuration.to_prepare do
  CanvasStatsd.settings = settings
end
