# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_cache"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei", "Cody Cutrer", "Jacob Burroughs"]
  spec.email         = ["evizitei@instructure.com", "cody@instructure.com", "jburroughs@instructure.com"]
  spec.summary       = "Instructure's caching capabilities, all in one place"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "config_file"

  # redis things required in canvas
  spec.add_dependency "digest-murmurhash", ">= 1.1.0"
  spec.add_dependency "redis", ">= 4.1.0"
  spec.add_dependency "redis-scripting", ">= 1.0.0"

  spec.add_dependency "guardrail", ">= 2.0.0"
  spec.add_dependency "inst_statsd", ">= 2.1.0"
  spec.add_dependency "sentry-ruby", "~> 5.10"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop"
end
