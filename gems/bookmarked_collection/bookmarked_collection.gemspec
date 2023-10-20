# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "bookmarked_collection"
  spec.version       = "1.0.0"
  spec.authors       = ["Raphael Weiner", "Nick Cloward"]
  spec.email         = ["rweiner@pivotallabs.com", "nickc@instructure.com"]
  spec.summary       = "Bookmarked collections for Canvas"

  spec.files         = Dir.glob("{lib}/**/*") + %w[Rakefile]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 3.2"
  spec.add_dependency "folio-pagination", "~> 0.0.12"
  spec.add_dependency "railties", ">= 3.2"
  spec.add_dependency "will_paginate", ">= 3.0", "< 5.0"

  spec.add_dependency "json_token"
  spec.add_dependency "paginated_collection"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "sqlite3"
end
