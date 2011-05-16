require File.dirname(__FILE__) + '/delayed/message_sending'
require File.dirname(__FILE__) + '/delayed/performable_method'
require File.dirname(__FILE__) + '/delayed/backend/base'
require File.dirname(__FILE__) + '/delayed/backend/active_record'
require File.dirname(__FILE__) + '/delayed/worker'
require File.dirname(__FILE__) + '/delayed/yaml_extensions'

Delayed::Job = Delayed::Backend::ActiveRecord::Job

Object.send(:include, Delayed::MessageSending)
Module.send(:include, Delayed::MessageSending::ClassMethods)
