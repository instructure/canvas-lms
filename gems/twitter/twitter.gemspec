# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "twitter"
  spec.version       = "1.0.0"
  spec.authors       = ["Raphael Weiner"]
  spec.email         = ["rweiner@pivotallabs.com"]
  spec.summary       = "Gem for posting to Twitter"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "html_text_helper"
  spec.add_dependency "oauth"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
