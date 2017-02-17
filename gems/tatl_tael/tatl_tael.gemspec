# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "tatl_tael"
  spec.version       = "0.0.1"
  spec.authors       = ["Landon Wilkins"]
  spec.email         = ["lwilkins@instructure.com"]
  spec.summary       = "Commit level linting."

  spec.files         = Dir.glob("{lib,spec,bin}/**/*")
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.5.0"
end
