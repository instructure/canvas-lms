# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "incoming_mail_processor"
  spec.version       = "0.0.1"
  spec.authors       = ["Jon Willesen"]
  spec.email         = ["jonw@instructure.com"]
  spec.summary       = "Read mail from IMAP inbox and process it."

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.2"

  spec.add_dependency "aws-sdk-s3"
  spec.add_dependency "aws-sdk-sqs"
  spec.add_dependency "html_text_helper"
  spec.add_dependency "inst_statsd"
  spec.add_dependency "mail", "~> 2.7.0"
  spec.add_dependency "utf8_cleaner"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webrick"
end
