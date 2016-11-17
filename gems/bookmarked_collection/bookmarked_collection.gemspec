# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "bookmarked_collection"
  spec.version       = "1.0.0"
  spec.authors       = ["Raphael Weiner", "Nick Cloward"]
  spec.email         = ["rweiner@pivotallabs.com", "nickc@instructure.com"]
  spec.summary       = %q{Bookmarked collections for Canvas}

  spec.files         = Dir.glob("{lib}/**/*") + %w(Rakefile)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "folio-pagination", "0.0.11"
  spec.add_dependency "will_paginate", "~> 3.0"
  spec.add_dependency "rails", ">= 3.2", "< 5.1"

  spec.add_dependency "paginated_collection"
  spec.add_dependency "json_token"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.99.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "byebug"

end
