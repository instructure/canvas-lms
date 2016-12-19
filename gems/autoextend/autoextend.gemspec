# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "autoextend"
  spec.version       = "1.0.0"
  spec.authors       = ["Cody Cutrer"]
  spec.email         = ["cody@instructure.com"]
  spec.summary       = %q{Framework for delaying monkey patches until the base class is defined}

  spec.files         = Dir.glob("{lib|spec}/**/*")
  spec.require_paths = ["lib"]
  spec.test_files    = spec.files.grep(%r{^spec/})

  spec.required_ruby_version = '~> 2.0'

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activesupport", "<5.1"
end
