# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_security"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = "Instructure gem for checking sigs and such"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "canvas_cache"
  spec.add_dependency "canvas_errors"
  spec.add_dependency "dynamic_settings"
  spec.add_dependency "json-jwt"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop"
end
