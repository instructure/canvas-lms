# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "acts_as_list"
  spec.version       = "0.0.1"
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = %q{This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list.}
  spec.homepage      = "https://github.com/instructure/canvas-lms"
  spec.license       = "AGPL"

  spec.files         = Dir.glob("{lib,spec}/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails', ">= 3.2"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "sqlite3"
end
