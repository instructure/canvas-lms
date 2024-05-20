# frozen_string_literal: true

require_relative "lib/canvas_partman/version"

Gem::Specification.new do |spec|
  spec.name          = "canvas_partman"
  spec.version       = CanvasPartman::VERSION
  spec.authors       = ["Ahmad Amireh"]
  spec.email         = ["ahmad@instructure.com"]
  spec.summary       = "PostgreSQL partitioning manager and helper."
  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[Gemfile LICENSE.txt README.md]
  spec.require_paths = ["lib"]
  spec.license       = "AGPL"

  spec.add_dependency "activerecord", ">= 6.1", "< 7.2"
  spec.add_dependency "activerecord-pg-extensions", "~> 0.4"
  spec.add_dependency "pg", ">= 0.17", "< 2.0"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
