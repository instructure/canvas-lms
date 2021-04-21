# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubocop_canvas/version'

Gem::Specification.new do |spec|
  spec.name          = "rubocop-canvas"
  spec.version       = Rubocop::Canvas::VERSION
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = %q{custom cops for canvas}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rubocop", "~> 0.68.0"
  spec.add_runtime_dependency "jira_ref_parser", "1.0.1"
  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "pry", "~> 0.10.1"
  spec.add_development_dependency "pry-nav", "~> 0.2.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "activesupport", "~> 5.1"
  spec.add_development_dependency "activerecord", "~> 5.1"
  spec.add_development_dependency "byebug"
end
