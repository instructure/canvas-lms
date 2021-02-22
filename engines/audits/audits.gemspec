$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "audits/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "audits"
  spec.version     = Audits::VERSION
  spec.authors     = ["evizitei"]
  spec.email       = ["evizitei@instructure.com"]
  spec.summary     = "Canvas Audit Trail"
  spec.description = "append-only log of important changes within canvas"
  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.2.4.5"
  spec.add_dependency "switchman", '>= 2.0.3'
  spec.add_dependency "canvas_cassandra"
  spec.add_dependency "dynamic_settings"
  spec.add_dependency "event_stream"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "brakeman"
  spec.add_development_dependency "byebug"
end