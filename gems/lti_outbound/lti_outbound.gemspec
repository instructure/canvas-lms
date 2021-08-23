# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'lti_outbound'
  spec.version       = '0.0.1'
  spec.authors       = ['Brian Palmer']
  spec.email         = ['brianp@instructure.com']
  spec.summary       = %q{LTI consumer service}
  spec.homepage      = 'https://github.com/instructure/canvas-lms'
  spec.license       = 'AGPL'

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(LICENSE.txt Rakefile README.md test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'i18n'
  spec.add_dependency 'oauth'

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
end
