# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_sort"
  spec.version       = "1.0.0"
  spec.authors       = ["Nick Cloward"]
  spec.email         = ["ncloward@instructure.com"]
  spec.summary       = "Canvas Sort"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
