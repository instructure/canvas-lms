def environment_configuration(_config)
  CanvasRails::Application.configure do
    yield(config)
  end
end

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
CanvasRails::Application.initialize!
