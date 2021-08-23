# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "event_stream"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = %q{Instructure event stream gem}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'bookmarked_collection'
  spec.add_dependency 'canvas_cassandra'
  spec.add_dependency 'inst_statsd'
  spec.add_dependency 'json_token'
  spec.add_dependency 'paginated_collection'

  spec.add_dependency 'rails', ">= 4.2"

  spec.add_development_dependency 'bundler', "~> 2.2"
  spec.add_development_dependency 'rspec', "~> 3.5.0"
  spec.add_development_dependency 'sqlite3'
end
