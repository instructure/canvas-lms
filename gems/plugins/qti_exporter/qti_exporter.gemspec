$:.push File.expand_path("../lib", __FILE__)

require 'qti_exporter/version'

Gem::Specification.new do |spec|
  spec.name          = "qti_exporter"
  spec.version       = QtiExporter::VERSION
  spec.authors       = ["Cody Cutrer"]
  spec.email         = ["cody@instructure.com"]
  spec.homepage      = "http://www.instructure.com"
  spec.summary       = %q{QTI Exporter}

  spec.files = Dir["{app,lib}/**/*"]
  spec.test_files = Dir["spec_canvas/**/*"]

  spec.add_dependency "rails", ">= 3.2", "< 4.2"
end
