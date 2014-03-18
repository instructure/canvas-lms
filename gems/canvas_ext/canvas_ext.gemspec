# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

unless defined?(CANVAS_RAILS3)
  require File.expand_path("../../../config/canvas_rails3", __FILE__)
end

Gem::Specification.new do |spec|
  spec.name          = "canvas_ext"
  spec.version       = "1.0.0"
  spec.authors       = ["Nick Cloward"]
  spec.email         = ["ncloward@instructure.com"]
  spec.summary       = %q{Monkey Patches for core classes}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if CANVAS_RAILS3
    spec.add_dependency "tzinfo"
    spec.add_dependency "activesupport", "~>3.2"
  else
    spec.add_dependency "activesupport", "~>2.3"
  end

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
