# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_breach_mitigation"
  spec.version       = '0.0.1'
  spec.authors       = ["Raphael Weiner", "David Julia"]
  spec.email         = ["rweiner@pivotallabs.com", "djulia@pivotallabs.com"]
  spec.summary       = %q{Subset of breach-mitigation-rails gem}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(LICENSE.txt README.md test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec", "2.99.0"
end
