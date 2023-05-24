# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "stringify_ids"
  spec.version       = "1.0.0"
  spec.authors       = ["Jacob Fugal", "Simon Williams"]
  spec.email         = ["jacob@instructure.com", "simon@instructure.com"]
  spec.summary       = "Methods to convert hash keys named 'id' or that end in 'id' from ints to strings, to avoid javascript floating point errors in javascript when receiving the JSON representation of that hash."

  spec.files         = Dir.glob("{lib}/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rspec", "~> 3.12"
end
