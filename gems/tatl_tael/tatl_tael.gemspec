# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "tatl_tael"
  spec.version       = "0.0.1"
  spec.authors       = ["Landon Wilkins"]
  spec.email         = ["lwilkins@instructure.com"]
  spec.summary       = "Commit level linting."

  spec.files         = Dir.glob("{lib,spec,bin}/**/*")
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "fakefs", "~> 1.2"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "timecop", "0.9.5"
end
