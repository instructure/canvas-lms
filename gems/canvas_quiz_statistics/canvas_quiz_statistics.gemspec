# coding: utf-8
# frozen_string_literal: true

require File.join(%W[#{File.dirname(__FILE__)} lib canvas_quiz_statistics version])

Gem::Specification.new do |spec|
  spec.name          = 'canvas_quiz_statistics'
  spec.version       = CanvasQuizStatistics::VERSION
  spec.authors       = ['Ahmad Amireh']
  spec.email         = ['ahmad@instructure.com']
  spec.summary       = %q{Bundle of statistics generators for quizzes and quiz questions.}
  spec.files         = Dir.glob("lib/**/*") + %w[ LICENSE.txt README.md Rakefile ]
  spec.test_files    = spec.files.grep(%r{spec})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'html_text_helper'

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', "~> 3.5.0"
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'terminal-notifier-guard'
  spec.add_development_dependency 'listen', "3.0.8"
end
