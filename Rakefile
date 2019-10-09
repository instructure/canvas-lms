# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/testtask'
Bundler.require(:i18n_tools)

CanvasRails::Application.load_tasks

if ENV['KNAPSACK_ENABLED'] == '1' && defined?(Knapsack)
  require 'spec/support/knapsack_extensions'
  Knapsack.load_tasks
end

