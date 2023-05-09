# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_ext"
  spec.version       = "1.0.0"
  spec.authors       = ["Nick Cloward"]
  spec.email         = ["ncloward@instructure.com"]
  spec.summary       = "Monkey Patches for core classes"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.2"
  spec.add_dependency "tzinfo"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
