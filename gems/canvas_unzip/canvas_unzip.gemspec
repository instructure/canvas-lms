# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_unzip"
  spec.version       = "0.0.1"
  spec.authors       = ["Jeremy Stanley"]
  spec.email         = ["jeremy@instructure.com"]
  spec.summary       = "Safe archive extraction"

  spec.files         = Dir.glob("{lib,test}/**/*") + %w[Rakefile]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "canvas_mimetype_fu"
  spec.add_dependency "rubyzip", "~> 2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
end
