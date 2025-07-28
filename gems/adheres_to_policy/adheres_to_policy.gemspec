# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "adheres_to_policy"
  spec.version       = "0.0.1"
  spec.authors       = ["Raphael Weiner", "Stephan Hagemann"]
  spec.email         = ["rweiner@pivotallabs.com", "stephan@pivotallabs.com"]
  spec.summary       = "The canvas adheres to policy gem"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[Rakefile README.md test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "< 8.0"
end
