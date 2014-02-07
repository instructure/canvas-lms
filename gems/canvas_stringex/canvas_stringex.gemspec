# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

CANVAS_RAILS3 = !!ENV['CANVAS_RAILS3'] || File.exist?(File.expand_path("../../RAILS3", __FILE__))

Gem::Specification.new do |spec|
  spec.name          = "canvas_stringex"
  spec.version       = '0.0.1'
  spec.authors       = ["Raphael Weiner", "Stephan Hagemann"]
  spec.email         = ["rweiner@pivotallabs.com", "stephan@pivotallabs.com"]
  spec.summary       = %q{Instructure fork of the stringex gem}

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if !CANVAS_RAILS3
    spec.add_dependency 'fake_arel', '1.4.0'
  end

  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
end
