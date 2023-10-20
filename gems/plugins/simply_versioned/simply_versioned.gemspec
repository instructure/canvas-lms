# frozen_string_literal: true

require_relative "lib/simply_versioned/gem_version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "simply_versioned"
  s.version     = SimplyVersioned::VERSION
  s.authors     = ["Ethan Vizitei"]
  s.email       = ["evizitei@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Instructure-maintained fork of simply_versioned"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "activerecord", ">= 3.2"
end
