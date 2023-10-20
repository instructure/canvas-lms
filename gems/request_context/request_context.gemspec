# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "request_context"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = "Instructure gem for managing http request metadata"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack"
  spec.add_dependency "canvas_security"
  spec.add_dependency "railties"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop"
end
