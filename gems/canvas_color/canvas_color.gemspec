# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_color"
  spec.version       = "0.0.1"
  spec.authors       = ["Mark Severson", "Simon Williams"]
  spec.email         = ["markse@instructure.com", "simon@instructure.com"]
  spec.summary       = "Instructure color gem"

  spec.files         = Dir.glob("{lib,test}/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
end
