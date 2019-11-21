# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_panda_pub"
  spec.version       = "1.0.0"
  spec.authors       = ["Zach Wily"]
  spec.email         = ["zach@instructure.com"]
  spec.summary       = %q{Canvas PandaPub}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_dependency "canvas_http"
  spec.add_dependency "json-jwt", "~> 1.10"

  spec.add_development_dependency "bundler", ">= 1.5", "< 3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end

