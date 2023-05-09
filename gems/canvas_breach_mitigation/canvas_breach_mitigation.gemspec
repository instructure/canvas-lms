# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_breach_mitigation"
  spec.version       = "0.0.1"
  spec.authors       = ["Raphael Weiner", "David Julia"]
  spec.email         = ["rweiner@pivotallabs.com", "djulia@pivotallabs.com"]
  spec.summary       = "Subset of breach-mitigation-rails gem"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[LICENSE.txt README.md test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
