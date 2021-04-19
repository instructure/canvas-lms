# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_dynamodb"
  spec.version       = "0.0.1"
  spec.authors       = ["Brent Burgoyne"]
  spec.email         = ["brent@instructure.com"]
  spec.summary       = %q{DynamoDB wrapper for Canvas LMS}
  spec.homepage      = "https://github.com/instructure/canvas-lms"
  spec.license       = "AGPL"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(Rakefile test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'aws-sdk-dynamodb', '~> 1.32'
  spec.add_runtime_dependency 'aws-sdk-applicationautoscaling', '~> 1.26'

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.7.0"
end
