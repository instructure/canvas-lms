# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "academic_benchmark"
  spec.version       = "1.1.0"
  spec.authors       = ["Simon Williams"]
  spec.email         = ["simon@instructure.com"]
  spec.homepage      = "http://www.instructure.com"
  spec.summary       = "Academic Benchmark outcome importer"

  spec.files = Dir["{app,config,db,lib}/**/*"]

  spec.add_dependency "academic_benchmarks", "~> 1.1.0"
  spec.add_dependency "railties", ">= 3.2"
end
