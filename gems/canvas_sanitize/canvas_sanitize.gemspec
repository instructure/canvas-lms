# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_sanitize"
  spec.version       = "0.0.1"
  spec.authors       = ["Raphael Weiner", "Stephan Hagemann"]
  spec.email         = ["rweiner@pivotallabs.com", "stephan@pivotallabs.com"]
  spec.summary       = "The canvas sanitizer gem"

  spec.files         = Dir.glob("{lib}/**/*") + %w[Rakefile README.md]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sanitize", "~> 7.0"
end
