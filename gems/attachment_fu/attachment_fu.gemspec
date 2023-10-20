# frozen_string_literal: true

require_relative "lib/attachment_fu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "attachment_fu"
  s.version     = AttachmentFu::VERSION
  s.authors     = ["Rick Olson", "Brian Palmer"]
  s.email       = ["brianp@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Instructure-maintained fork of attachment_fu"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "activerecord", ">= 3.2"
  s.add_dependency "railties", ">= 3.2"
end
