require 'active_support/concern'

module Canvas::GradeValidations
  extend ActiveSupport::Concern

  included do
    validates_length_of :grade, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  end
end
