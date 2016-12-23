# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "diigo"
  spec.version       = "1.0.0"
  spec.authors       = ["Brian Whitmer"]
  spec.email         = ["brian@instructure.com"]
  spec.summary       = %q{Diigo}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.5.0"
end
