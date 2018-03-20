$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "broadcast_policy/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "broadcast_policy"
  s.version     = BroadcastPolicy::VERSION
  s.authors     = ["Ethan Vizitei"]
  s.email       = ["ethan@instructure.com"]
  s.homepage    = "http://www.instructure.com"
  s.summary     = "Notification management for ActiveRecord models in Canvas"

  s.files = Dir["{lib}/**/*"]
  s.test_files = Dir["spec_canvas/**/*"]

  s.add_dependency "activesupport"
  s.add_dependency "after_transaction_commit"
  s.add_development_dependency "rspec", "~> 3.5.0"
  s.add_development_dependency "byebug"
  s.add_development_dependency "pry"
end
