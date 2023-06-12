# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "i18n_extraction"
  spec.version = "0.0.1"
  spec.authors = ["Raphael Weiner"]
  spec.email = ["rweiner@pivotallabs.com"]
  spec.summary = "i18n extraction for Instructure"

  spec.files = Dir.glob("{lib,spec}/**/*") + %w[Rakefile test.sh]
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.2"
  spec.add_dependency "i18nliner", "~> 0.1"
  spec.add_dependency "ruby_parser", "~> 3.7"
  spec.add_dependency "sexp_processor", "~> 4.14", ">= 4.14.1"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
