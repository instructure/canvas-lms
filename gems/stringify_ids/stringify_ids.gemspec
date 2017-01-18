# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "stringify_ids"
  spec.version       = "1.0.0"
  spec.authors       = ["Jacob Fugal", "Simon Williams"]
  spec.email         = ["jacob@instructure.com", "simon@instructure.com"]
  spec.summary       = %q{Methods to convert hash keys named 'id' or that end in 'id' from ints to strings, to avoid javascript floating point errors in javascript when receiving the JSON representation of that hash.}

  spec.files         = Dir.glob("{lib}/**/*")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rspec", "3.4.0"
end
