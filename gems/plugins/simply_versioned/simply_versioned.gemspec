$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "simply_versioned/gem_version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "simply_versioned"
  s.version     = SimplyVersioned::VERSION
  s.authors     = ["Matt Mower", "Brian Palmer"]
  s.email       = ["brianp@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Instructure-maintained fork of simply_versioned"

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.test_files = Dir["spec_canvas/**/*"]

  s.add_dependency "rails", ">= 3.2"
end
