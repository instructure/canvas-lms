# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "legacy_multipart"
  spec.version       = "0.0.1"
  spec.authors       = ["Raphael Weiner"]
  spec.email         = ["rweiner@pivotallabs.com"]
  spec.summary       = "Multipart helper to prepare an HTTP POST request with file upload"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "canvas_slug"
  spec.add_dependency "mime-types", "~> 3.2"
end
