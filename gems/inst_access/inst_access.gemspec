# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "inst_access"
  spec.version       = "0.1.0"
  spec.authors       = ["Michael Ziwisky"]
  spec.email         = ["mziwisky@instructure.com"]
  spec.summary       = %q{Generation, parsing, and validation of Instructure access tokens}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '>= 5'
  spec.add_dependency 'json-jwt', '1.13.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'timecop'
end
