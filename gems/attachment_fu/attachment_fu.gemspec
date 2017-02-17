$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "attachment_fu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "attachment_fu"
  s.version     = AttachmentFu::VERSION
  s.authors     = ["Rick Olson", "Brian Palmer"]
  s.email       = ["brianp@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Instructure-maintained fork of attachment_fu"

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.test_files = Dir["spec_canvas/**/*"]

  s.add_dependency "rails", ">= 3.2", "< 5.1"
end
