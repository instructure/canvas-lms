$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "delayed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "delayed_job"
  s.version     = Delayed::VERSION
  s.authors     = ["Tobias Luetke", "Brian Palmer"]
  s.email       = ["brianp@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Instructure-maintained fork of delayed_job"

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.test_files = Dir["spec_canvas/**/*"]

  s.add_dependency "rails", ">= 3.2", "< 4.2"
  s.add_dependency 'rufus-scheduler', '2.0.6'
  s.add_dependency 'redis-scripting', '1.0.1'
end

