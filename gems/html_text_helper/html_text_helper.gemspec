# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "html_text_helper"
  spec.version       = '0.0.1'
  spec.authors       = ["Zach Pendleton", "Stephan Hagemann"]
  spec.email         = ["zachp@instructure.com", "stephan@pivotallabs.com"]
  spec.summary       = %q{Html text helpers}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'nokogiri', '~> 1.5.6'
  spec.add_dependency 'sanitize', '2.0.3'
  spec.add_dependency 'canvas_text_helper'

  spec.add_dependency 'activesupport', ">= 3.2", "< 4.2"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec", "2.99.0"
end
