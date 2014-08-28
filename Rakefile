# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
Bundler.require(:i18n_tools)

CanvasRails::Application.load_tasks

begin; require 'parallelized_specs/lib/parallelized_specs/tasks'; rescue LoadError; end
