# frozen_string_literal: true

require_relative "lib/account_reports/version"

Gem::Specification.new do |spec|
  spec.name          = "account_reports"
  spec.version       = AccountReports::VERSION
  spec.authors       = ["Rob Orton"]
  spec.email         = ["rob@instructure.com"]
  spec.homepage      = "https://www.instructure.com"
  spec.summary       = "Account Level Reports"

  spec.files = Dir["{app,config,db,lib}/**/*"]

  spec.add_dependency "railties", ">= 3.2"
end
