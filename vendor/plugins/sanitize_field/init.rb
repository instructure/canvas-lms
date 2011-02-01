require 'sanitize_field'
ActiveRecord::Base.send :include, Instructure::SanitizeField