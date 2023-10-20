# frozen_string_literal: true

require_relative "lib/turnitin_api/version"

Gem::Specification.new do |spec|
  spec.name          = "turnitin_api"
  spec.version       = TurnitinApi::VERSION
  spec.authors       = ["Brad Horrocks"]
  spec.email         = ["bhorrocks@instructure.com"]
  spec.summary       = "Turnitin integration at your fingertips"
  spec.license       = "MIT"

  spec.files         = Dir["{lib}/**/*"] + ["LICENSE.txt", "README.md", "Changelog.txt"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-follow_redirects", "~> 0.3"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "inst_statsd"
  spec.add_dependency "simple_oauth", "~> 0.3"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.0"
end
