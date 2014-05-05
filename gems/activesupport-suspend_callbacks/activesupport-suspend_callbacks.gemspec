# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

unless defined?(CANVAS_RAILS3)
  CANVAS_RAILS3 = !!ENV["CANVAS_RAILS3"] || File.exist?(File.expand_path("../../RAILS3", __FILE__))
end

Gem::Specification.new do |spec|
  spec.name          = "activesupport-suspend_callbacks"
  spec.version       = '0.0.1'
  spec.authors       = ["Jacob Fugal"]
  spec.email         = ["jacob@instructure.com"]
  spec.summary       = %q{Temporarily suspend specific ActiveSupport::Callbacks callbacks}

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(LICENSE.txt Rakefile README.md test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if CANVAS_RAILS3
    spec.add_dependency "activesupport", "3.2.17"
  else
    spec.add_dependency "activesupport", "~>2.3.17"
  end

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "mocha"
end
