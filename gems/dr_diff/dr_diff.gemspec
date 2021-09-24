# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "dr_diff"
  spec.version       = "0.0.1"
  spec.authors       = ["Landon Wilkins"]
  spec.email         = ["lwilkins@instructure.com"]
  spec.summary       = "Run linters only on the git diff."

  spec.files         = Dir.glob("{lib,spec,bin}/**/*")
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_dependency "gergich", "2.0.0"

  spec.add_development_dependency "byebug", "~> 11.1"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "rspec-mocks"
end
