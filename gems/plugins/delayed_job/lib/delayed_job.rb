module Delayed
  MIN_PRIORITY = 0
  HIGH_PRIORITY = 0
  NORMAL_PRIORITY = 10
  LOW_PRIORITY = 20
  LOWER_PRIORITY = 50
  MAX_PRIORITY = 1_000_000
end

require 'delayed/backend/base'
require 'delayed/backend/active_record'
require 'delayed/backend/redis/job'
require 'delayed/batch'
require 'delayed/job_tracking'
require 'delayed/lifecycle'
require 'delayed/message_sending'
require 'delayed/performable_method'
require 'delayed/periodic'
require 'delayed/pool'
require 'delayed/stats'
require 'delayed/worker'
require 'delayed/yaml_extensions'

Object.send(:include, Delayed::MessageSending)
Module.send(:include, Delayed::MessageSending::ClassMethods)
