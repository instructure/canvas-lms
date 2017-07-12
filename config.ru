# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
$booted = true
if defined?(CanvasRails)
  run CanvasRails::Application
else
  run ActionController::Dispatcher.new
end
