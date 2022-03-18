# frozen_string_literal: true

require_relative "lib/canvas_partman/version"

Gem::Specification.new do |spec|
  spec.name          = "canvas_partman"
  spec.version       = CanvasPartman::VERSION
  spec.authors       = ["Ahmad Amireh"]
  spec.email         = ["ahmad@instructure.com"]
  spec.summary       = "PostgreSQL partitioning manager and helper."
  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[Gemfile LICENSE.txt README.md]
  spec.test_files    = spec.files.grep(/spec/)
  spec.require_paths = ["lib"]
  spec.license       = "AGPL"

  spec.add_dependency "activerecord", ">= 3.2", "< 7.0"
  spec.add_dependency "activerecord-pg-extensions", "~> 0.4"
  spec.add_dependency "pg", ">= 0.17", "< 2.0"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rspec", "~> 3.5.0"
end
