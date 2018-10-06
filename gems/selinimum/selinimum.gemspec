# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = "selinimum"
  spec.version = '0.0.1'
  spec.authors = ["Jon Jensen"]
  spec.email = ["jon@instructure.com"]
  spec.summary = %q{run the minimum selenium necessary for your commit}

  spec.files = Dir.glob("{lib,spec,bin}/**/*") + %w(test.sh)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  # pin to exactly what canvas pins to, to avoid dependency issues when invoked
  # directly from bin/selinimize
  spec.add_dependency "aws-sdk-s3", "1.19.0"
  spec.add_dependency "activesupport", ">= 3.2"
  spec.add_dependency "activerecord", ">= 3.2"
  spec.add_dependency "globby", ">= 0.1.2"
end
