# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "autoextend"
  spec.version       = "1.0.0"
  spec.authors       = ["Cody Cutrer"]
  spec.email         = ["cody@instructure.com"]
  spec.summary       = "Framework for delaying monkey patches until the base class is defined"

  spec.files         = Dir.glob("{lib|spec}/**/*")
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec", "~> 3.12"
end
