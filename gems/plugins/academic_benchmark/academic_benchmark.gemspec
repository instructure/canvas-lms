# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)

require 'academic_benchmark/version'

Gem::Specification.new do |spec|
  spec.name          = "academic_benchmark"
  spec.version       = AcademicBenchmark::VERSION
  spec.authors       = ["Bracken Mosbacker", "Simon Williams"]
  spec.email         = ["bracken@instructure.com", "simon@instructure.com"]
  spec.homepage      = "http://www.instructure.com"
  spec.summary       = %q{Academic Benchmark outcome importer}

  spec.files = Dir["{app,config,db,lib}/**/*"]
  spec.test_files = Dir["spec_canvas/**/*"]

  spec.add_dependency "rails", ">= 3.2"
  spec.add_dependency "academic_benchmarks", "~> 1.1.0"
end
