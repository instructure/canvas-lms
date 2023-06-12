# frozen_string_literal: true

require_relative "lib/respondus_soap_endpoint/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "respondus_soap_endpoint"
  s.version     = RespondusSoapEndpoint::VERSION
  s.authors     = ["Brian Palmer"]
  s.email       = ["brianp@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "SOAP Endpoint for Respondus QTI uploads"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "rails",             ">= 3.2"
  s.add_dependency "soap4r-middleware", "0.8.7"
  # in spite of the name, this fork of soap4r works with all rubies
  s.add_dependency "soap4r-ruby1.9",    "2.0.5"
end
