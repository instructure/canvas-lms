# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

unless defined?(CANVAS_RAILS3)
  require File.expand_path("../../../config/canvas_rails3", __FILE__)
end

Gem::Specification.new do |spec|
  spec.name          = "i18n_tasks"
  spec.version       = '0.0.1'
  spec.authors       = ["Raphael Weiner", "Stephan Hagemann"]
  spec.email         = ["rweiner@pivotallabs.com", "stephan@pivotallabs.com"]
  spec.summary       = %q{Instructure i18n tasks gem}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(Rakefile test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if CANVAS_RAILS3
    spec.add_dependency "activesupport", "~> 3.2"
  else
    spec.add_dependency "activesupport", "~> 2.3"
  end

  spec.add_dependency "i18n", "0.6.8"
  spec.add_dependency "ruby_parser", "3.1.3"
  spec.add_dependency "ya2yaml", "0.30"
  spec.add_dependency "i18n_extraction"
  spec.add_dependency "utf8_cleaner"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
