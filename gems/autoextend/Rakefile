require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.name = "spec"
  t.pattern = "spec/**/*_spec.rb"
end

task :default => :spec
