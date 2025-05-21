# frozen_string_literal: true

require_relative "lib/csv_diff/version"

Gem::Specification.new do |spec|
  spec.name          = "csv_diff"
  spec.version       = CsvDiff::VERSION
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = "Generate CSV diffs"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.require_paths = ["lib"]

  spec.add_dependency "csv"
  spec.add_dependency "sqlite3"
end
