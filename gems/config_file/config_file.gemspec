# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "config_file"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = %q{Instructure gem for loading config info from yaml on disk}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails', ">= 5.0"

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'byebug'

end