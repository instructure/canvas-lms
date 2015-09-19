# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "google_docs"
  spec.version       = "1.0.0"
  spec.authors       = ["Ken Romney"]
  spec.email         = ["kromney@instructure.com"]
  spec.summary       = %q{Google Docs}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ratom-nokogiri", "0.10.4"
  spec.add_dependency "oauth-instructure", "0.4.10"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.99.0"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "timecop"
end
