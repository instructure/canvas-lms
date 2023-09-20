# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "incoming_mail_processor"
  spec.version       = "0.0.1"
  spec.authors       = ["Jon Willesen"]
  spec.email         = ["jonw@instructure.com"]
  spec.summary       = "Read mail from IMAP inbox and process it."

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.2"

  spec.add_dependency "aws-sdk-s3"
  spec.add_dependency "aws-sdk-sqs"
  spec.add_dependency "canvas_errors"
  spec.add_dependency "html_text_helper"
  spec.add_dependency "inst_statsd"
  spec.add_dependency "mail", "~> 2.8"
  spec.add_dependency "net-imap"
  spec.add_dependency "net-pop"
  spec.add_dependency "net-smtp"
  spec.add_dependency "utf8_cleaner"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "timecop", "~> 0.9.5"
  spec.add_development_dependency "webrick"
end
