# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_panda_pub"
  spec.version       = "1.0.0"
  spec.authors       = ["Zach Wily"]
  spec.email         = ["zach@instructure.com"]
  spec.summary       = "Canvas PandaPub"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "canvas_http"
  spec.add_dependency "json-jwt", "~> 1.10"
end
