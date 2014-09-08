# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "json_token"
  spec.version       = "0.0.1"
  spec.authors       = ["Nick Cloward", "Joseph Rodriguez"]
  spec.email         = ["nickc@instructure.com", "jrodriguez@pivotallabs.com"]
  spec.summary       = %q{Convenience methods for encoding and decoding a slug of data into base64 encoded JSON}

  spec.files         = Dir.glob("{lib}/**/*") + %w(Rakefile)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'json', '1.8.1'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.99.0"
end
