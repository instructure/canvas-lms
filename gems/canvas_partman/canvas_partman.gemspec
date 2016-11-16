# coding: utf-8

require File.join(%W[#{File.dirname(__FILE__)} lib canvas_partman version])

Gem::Specification.new do |spec|
  spec.name          = 'canvas_partman'
  spec.version       = CanvasPartman::VERSION
  spec.authors       = ['Ahmad Amireh']
  spec.email         = ['ahmad@instructure.com']
  spec.summary       = 'PostgreSQL partitioning manager and helper.'
  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[ Gemfile LICENSE.txt README.md ]
  spec.test_files    = spec.files.grep(%r{spec})
  spec.require_paths = ['lib']
  spec.license       = 'AGPL'

  spec.add_dependency 'activerecord', '>= 3.2', '< 5.1'
  spec.add_dependency 'pg', '~> 0.17'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
end
