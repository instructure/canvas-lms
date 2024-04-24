# frozen_string_literal: true

require_relative "lib/moodle_importer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "moodle_importer"
  s.version     = MoodleImporter::VERSION
  s.authors     = ["August Thornton"]
  s.email       = ["august@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "%w{Account Course}"
  s.description = "This enables importing Moodle 1.9 and 2.x .zip/.mbz files to Canvas."

  s.files = Dir["{lib}/**/*"]

  s.add_dependency "moodle2cc", "0.2.46"
  s.add_dependency "rails", ">= 3.2"
end
