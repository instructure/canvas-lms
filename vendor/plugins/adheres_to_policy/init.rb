require 'adheres_to_policy'
ActiveRecord::Base.send :extend, Instructure::Adheres::Policy::ClassMethods