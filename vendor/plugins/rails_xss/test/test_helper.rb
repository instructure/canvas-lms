abort 'RAILS_ROOT=/path/to/rails/2.3/app rake test' unless ENV['RAILS_ROOT']
require File.expand_path('config/environment', ENV['RAILS_ROOT'])
require File.expand_path('../../init', __FILE__)
require 'active_support/test_case'
require 'test/unit'
