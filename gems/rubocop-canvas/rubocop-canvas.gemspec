# frozen_string_literal: true

require_relative "lib/rubocop_canvas/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-canvas"
  spec.version       = Rubocop::Canvas::VERSION
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = "custom cops for canvas"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "jira_ref_parser", "1.0.1"
  spec.add_dependency "outrigger", "~> 3.0", ">= 3.0.1"
  spec.add_dependency "railties", "~> 7.0"
  spec.add_dependency "rubocop", "~> 1.19"
  spec.add_dependency "rubocop-rails", "~> 2.19"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
