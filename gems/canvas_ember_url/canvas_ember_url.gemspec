# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_ember_url"
  spec.version       = "1.0.0"
  spec.authors       = ["Derek DeVries"]
  spec.email         = ["ddevries@instructure.com"]
  spec.summary       = %q{Map Rails URLs to Ember routes}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(Rakefile test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.14.1"
end
