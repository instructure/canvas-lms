# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "acts_as_list"
  spec.version       = "0.0.1"
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = "This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list."
  spec.homepage      = "https://github.com/instructure/canvas-lms"
  spec.license       = "AGPL"

  spec.files         = Dir.glob("{lib,spec}/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 3.2"

  spec.add_development_dependency "bundler", ">= 1.5", "< 3.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "sqlite3"
end
