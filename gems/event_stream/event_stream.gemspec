# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "event_stream"
  spec.version       = "0.1.0"
  spec.authors       = ["Ethan Vizitei"]
  spec.email         = ["evizitei@instructure.com"]
  spec.summary       = "Instructure event stream gem"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.2"
  spec.add_dependency "bookmarked_collection"
  spec.add_dependency "inst_statsd"
  spec.add_dependency "json_token"
  spec.add_dependency "paginated_collection"
end
