# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_dynamodb"
  spec.version       = "0.0.1"
  spec.authors       = ["Brent Burgoyne"]
  spec.email         = ["brent@instructure.com"]
  spec.summary       = "DynamoDB wrapper for Canvas LMS"
  spec.homepage      = "https://github.com/instructure/canvas-lms"
  spec.license       = "AGPL"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[Rakefile test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-applicationautoscaling", "~> 1.26"
  spec.add_dependency "aws-sdk-dynamodb", "~> 1.32"
  spec.add_dependency "benchmark", "~> 0.4"
end
