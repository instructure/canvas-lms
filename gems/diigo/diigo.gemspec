# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "diigo"
  spec.version       = "1.0.0"
  spec.authors       = ["Brian Whitmer"]
  spec.email         = ["brian@instructure.com"]
  spec.summary       = "Diigo"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
