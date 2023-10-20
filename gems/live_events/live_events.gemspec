# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "live_events"
  spec.version       = "1.0.0"
  spec.authors       = ["Zach Wily"]
  spec.email         = ["zach@instructure.com"]
  spec.summary       = "LiveEvents"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "aws-sdk-kinesis"
  spec.add_dependency "inst_statsd"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
