# frozen_string_literal: true

require_relative "lib/qti_exporter/version"

Gem::Specification.new do |spec|
  spec.name          = "qti_exporter"
  spec.version       = QtiExporter::VERSION
  spec.authors       = ["Cody Cutrer"]
  spec.email         = ["cody@instructure.com"]
  spec.homepage      = "http://www.instructure.com"
  spec.summary       = "QTI Exporter"

  spec.files = Dir["{app,lib}/**/*"]

  spec.add_dependency "rails", ">= 3.2"
end
