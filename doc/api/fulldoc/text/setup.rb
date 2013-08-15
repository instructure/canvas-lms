# encoding: utf-8
$:.unshift(File.dirname(__FILE__))
require 'controller_view'

def init
  apis = []
  controllers = run_verifier(options[:objects])
  controllers.each do |controller|
    ControllerView.new(controller).methods.each do |method|
      apis << method.to_swagger
    end
  end

  resource_listing = {
    "apiVersion" => "1.0",
    "swaggerVersion" => "1.2",
    "basePath" => "http://canvas.instructure.com/api/v1",
    # "resourcePath": "/pet"
    "apis" => apis,
    # "models": models,
  }

  filename = "api.json"
  puts "Writing API data to #{filename}"
  File.open(filename, "w") do |file|
    file.puts JSON.pretty_generate(resource_listing)
  end
end