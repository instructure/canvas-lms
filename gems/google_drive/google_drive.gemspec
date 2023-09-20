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

  spec.add_runtime_dependency "google-apis-drive_v3", "~> 0.43"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"
end
