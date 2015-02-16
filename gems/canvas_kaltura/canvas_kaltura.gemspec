# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_kaltura"
  spec.version       = "1.0.0"
  spec.authors       = ["Nick Cloward"]
  spec.email         = ["ncloward@instructure.com"]
  spec.summary       = %q{Canvas Kaltura}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_dependency "nokogiri", "1.5.6"
  spec.add_dependency "libxml-ruby", "~> 2.7"
  spec.add_dependency "canvas_http"
  spec.add_dependency "canvas_sort"
  spec.add_dependency "multipart"
  spec.add_dependency "canvas_slug"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.99.0"
  spec.add_development_dependency "webmock", "1.16.1"
end
