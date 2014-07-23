# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "incoming_mail_processor"
  spec.version       = "0.0.1"
  spec.authors       = ["Jon Willesen"]
  spec.email         = ["jonw@instructure.com"]
  spec.summary       = %q{Read mail from IMAP inbox and process it.}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~>3.2"

  spec.add_dependency "mail", "2.5.4"
  spec.add_dependency "html_text_helper"
  spec.add_dependency "utf8_cleaner"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec", "2.14.1"
  spec.add_development_dependency "mocha"
end
