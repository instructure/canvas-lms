# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("../config/canvas_rails3", __FILE__)

if CANVAS_RAILS2
  require File.expand_path('../config/boot', __FILE__)
else
  require File.expand_path('../config/application', __FILE__)
end

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

if CANVAS_RAILS2
  Dir["#{RAILS_ROOT}/gems/**/tasks/*.rake"].each { |ext| load ext }
  require 'tasks/rails'
else
  Dir["#{Rails.root}/gems/**/tasks/*.rake"].each { |ext| load ext }
  CanvasRails::Application.load_tasks
end
begin; require 'parallelized_specs/lib/parallelized_specs/tasks'; rescue LoadError; end
