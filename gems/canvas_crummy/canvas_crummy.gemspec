# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_crummy"
  spec.version       = '0.0.1'
  spec.authors       = ["Raphael Weiner", "David Julia"]
  spec.email         = ["rweiner@pivotallabs.com", "djulia@pivotallabs.com"]
  spec.summary       = %q{Instructure fork of crummy gem}

  spec.files         = Dir.glob("{lib}/**/*") + %w(LICENSE.txt README.md Rakefile)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
