# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "google_drive"
  spec.version       = "1.0.0"
  spec.authors       = ["Brad Humphrey"]
  spec.email         = ["brad@instructure.com"]
  spec.summary       = "Google Drive"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 3.2"
  spec.add_runtime_dependency  "google-api-client", "0.8.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"
  spec.add_dependency "faraday", "~> 0.17.3"
end
