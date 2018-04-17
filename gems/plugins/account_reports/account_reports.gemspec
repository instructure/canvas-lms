$:.push File.expand_path("../lib", __FILE__)

require 'account_reports/version'

Gem::Specification.new do |spec|
  spec.name          = "account_reports"
  spec.version       = AccountReports::VERSION
  spec.authors       = ["Rob Orton"]
  spec.email         = ["rob@instructure.com"]
  spec.homepage      = "https://www.instructure.com"
  spec.summary       = %q{Account Level Reports}

  spec.files = Dir["{app,config,db,lib}/**/*"]
  spec.test_files = Dir["spec_canvas/**/*"]

  spec.add_dependency "rails", ">= 3.2"
end
