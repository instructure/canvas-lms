# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require File.expand_path("../../../config/canvas_rails4", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "event_stream"
  spec.version       = "0.0.1"
  spec.authors       = ["Nick Cloward", "Mark Severson"]
  spec.email         = ["ncloward@instructure.com", "markse@instructure.com"]
  spec.summary       = %q{Instructure event stream gem}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'bookmarked_collection'
  spec.add_dependency 'canvas_cassandra'
  spec.add_dependency 'canvas_statsd'
  spec.add_dependency 'json_token'
  spec.add_dependency 'paginated_collection'

  spec.add_dependency 'rails', ">= 3.2", "< 4.2"
  unless CANVAS_RAILS3
    spec.add_dependency 'protected_attributes', '~>1.0'
  end

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rspec', "2.14.1"
  spec.add_development_dependency 'sqlite3'
end
