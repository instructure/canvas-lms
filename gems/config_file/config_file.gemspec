# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "config_file"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = "Instructure gem for loading config info from yaml on disk"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec"
end
