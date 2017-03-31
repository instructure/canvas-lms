# Initialize canvas statsd configuration. See config/statsd.yml.example.

Rails.configuration.to_prepare do
  CanvasStatsd.settings = ConfigFile.load("statsd") || {}
end
