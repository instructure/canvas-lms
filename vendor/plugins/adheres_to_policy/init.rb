require 'adheres_to_policy'
ActiveRecord::Base.send :extend, Instructure::AdheresToPolicy::ClassMethods