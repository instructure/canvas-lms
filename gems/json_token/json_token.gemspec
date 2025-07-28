# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "json_token"
  spec.version       = "0.0.1"
  spec.authors       = ["Nick Cloward", "Joseph Rodriguez"]
  spec.email         = ["nickc@instructure.com", "jrodriguez@pivotallabs.com"]
  spec.summary       = "Convenience methods for encoding and decoding a slug of data into base64 encoded JSON"

  spec.files         = Dir.glob("{lib}/**/*") + %w[Rakefile]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "json"
end
