# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_stringex"
  spec.version       = "0.0.1"
  spec.authors       = ["Raphael Weiner", "Stephan Hagemann"]
  spec.email         = ["rweiner@pivotallabs.com", "stephan@pivotallabs.com"]
  spec.summary       = "Instructure fork of the stringex gem"

  spec.files         = Dir.glob("{lib,test}/**/*") + %w[LICENSE.txt Rakefile README.rdoc test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "bundler", ">= 1.5", "< 3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "sqlite3"
end
