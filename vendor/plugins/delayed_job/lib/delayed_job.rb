module Delayed
  MIN_PRIORITY = 0
  HIGH_PRIORITY = 0
  NORMAL_PRIORITY = 10
  LOW_PRIORITY = 20
  LOWER_PRIORITY = 50
  MAX_PRIORITY = 1_000_000
end

require File.expand_path(File.dirname(__FILE__) + '/delayed/message_sending')
require File.expand_path(File.dirname(__FILE__) + '/delayed/performable_method')
require File.expand_path(File.dirname(__FILE__) + '/delayed/backend/base')
require File.expand_path(File.dirname(__FILE__) + '/delayed/backend/active_record')
require File.expand_path(File.dirname(__FILE__) + '/delayed/worker')
require File.expand_path(File.dirname(__FILE__) + '/delayed/lifecycle')
require File.expand_path(File.dirname(__FILE__) + '/delayed/yaml_extensions')

Object.send(:include, Delayed::MessageSending)
Module.send(:include, Delayed::MessageSending::ClassMethods)
