# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_crummy"
  spec.version       = "0.0.1"
  spec.authors       = ["Raphael Weiner", "David Julia"]
  spec.email         = ["rweiner@pivotallabs.com", "djulia@pivotallabs.com"]
  spec.summary       = "Instructure fork of crummy gem"

  spec.files         = Dir.glob("{lib}/**/*") + %w[LICENSE.txt README.md Rakefile]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
