require 'broadcast_policy'
ActiveRecord::Base.send :extend, Instructure::BroadcastPolicy::ClassMethods