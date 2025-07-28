# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "html_text_helper"
  spec.version       = "0.0.1"
  spec.authors       = ["Zach Pendleton", "Stephan Hagemann"]
  spec.email         = ["zachp@instructure.com", "stephan@pivotallabs.com"]
  spec.summary       = "Html text helpers"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "canvas_text_helper"
  spec.add_dependency "nokogiri"

  spec.add_dependency "sanitize", "~> 7.0"
  spec.add_dependency "twitter-text", "~> 3.1"

  spec.add_dependency "activesupport"
end
