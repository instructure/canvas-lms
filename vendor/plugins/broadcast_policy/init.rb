require 'broadcast_policy'
ActiveRecord::Base.send :extend, Instructure::Broadcast::Policy::ClassMethods