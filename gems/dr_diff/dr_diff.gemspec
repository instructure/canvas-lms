# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "dr_diff"
  spec.version       = "0.0.1"
  spec.authors       = ["Landon Wilkins"]
  spec.email         = ["lwilkins@instructure.com"]
  spec.summary       = "Run linters only on the git diff."

  spec.files         = Dir.glob("{lib,spec,bin}/**/*")
  spec.require_paths = ["lib"]

  spec.add_dependency "gergich", "~> 2.1"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-mocks"
end
