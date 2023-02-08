# frozen_string_literal: true

require_relative "lib/rubocop_canvas/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-canvas"
  spec.version       = Rubocop::Canvas::VERSION
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = "custom cops for canvas"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "jira_ref_parser", "1.0.1"
  spec.add_dependency "outrigger", "~> 3.0"
  spec.add_dependency "rubocop", "~> 1.19"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry", "~> 0.10.1"
  spec.add_development_dependency "pry-nav", "~> 0.2.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5.0"
end
