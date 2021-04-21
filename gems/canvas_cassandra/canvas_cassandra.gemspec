# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_cassandra"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = %q{Cassandra wrapper for Canvas LMS}
  spec.homepage      = "https://github.com/instructure/canvas-lms"
  spec.license       = "AGPL"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(Rakefile test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'cassandra-cql', '~> 1.2.2'
  spec.add_dependency "rails", ">= 5.0"
  spec.add_dependency "config_file"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "byebug"
end
