require File.dirname(__FILE__) + '/delayed/message_sending'
require File.dirname(__FILE__) + '/delayed/performable_method'
require File.dirname(__FILE__) + '/delayed/backend/base'
require File.dirname(__FILE__) + '/delayed/worker'

Object.send(:include, Delayed::MessageSending)   
Module.send(:include, Delayed::MessageSending::ClassMethods)

Delayed::Worker.backend = :active_record

if defined?(Merb::Plugins)
  Merb::Plugins.add_rakefiles File.dirname(__FILE__) / 'delayed' / 'tasks'
end
