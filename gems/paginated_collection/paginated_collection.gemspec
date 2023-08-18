# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "paginated_collection"
  spec.version       = "1.0.0"
  spec.authors       = ["Brian Palmer"]
  spec.email         = ["brianp@instructure.com"]
  spec.summary       = "Paginated Collection gem"

  spec.files         = Dir.glob("{lib}/**/*") + %w[Rakefile]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "folio-pagination", "~> 0.0.12"
  spec.add_dependency "will_paginate", ">= 3.0", "< 5.0"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "sqlite3"
end
