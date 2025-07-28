# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_http"
  spec.version       = "1.0.0"
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = "Canvas HTTP"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[Rakefile test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "canvas_cache"
  spec.add_dependency "legacy_multipart"
  spec.add_dependency "logger", "~> 1.5"
end
