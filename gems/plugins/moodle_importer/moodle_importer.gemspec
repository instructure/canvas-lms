$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "moodle_importer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "moodle_importer"
  s.version     = Moodle::VERSION
  s.authors     = ["August Thornton"]
  s.email       = ["august@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "%w{Account Course}"
  s.description = "This enables importing Moodle 1.9 and 2.x .zip/.mbz files to Canvas."

  s.files = Dir["{lib}/**/*"]
  s.test_files = Dir["spec_canvas/**/*"]

  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "moodle2cc", "0.2.39"
end
