# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "tatl_tael"
  spec.version       = "0.0.1"
  spec.authors       = ["Landon Wilkins"]
  spec.email         = ["lwilkins@instructure.com"]
  spec.summary       = "Commit level linting."

  spec.files         = Dir.glob("{lib,spec,bin}/**/*")
  spec.require_paths = ["lib"]
end
