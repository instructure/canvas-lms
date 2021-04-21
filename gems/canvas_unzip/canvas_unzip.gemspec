# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_unzip"
  spec.version       = "0.0.1"
  spec.authors       = ["Jeremy Stanley"]
  spec.email         = ["jeremy@instructure.com"]
  spec.summary       = %q{Safe archive extraction}

  spec.files         = Dir.glob("{lib,test}/**/*") + %w(Rakefile)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "canvas_mimetype_fu"
  spec.add_dependency "rubyzip", "~> 2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.5.0"
end
