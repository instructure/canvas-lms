class WeakParameters < ActiveSupport::HashWithIndifferentAccess
end

# default to *non* strong parameters
ActionController::Base.class_eval do
  def params
    @_params ||= WeakParameters.new(request.parameters)
  end

  def strong_params
    @_strong_params ||= ActionController::Parameters.new(request.parameters)
  end

  def params=(val)
    @_strong_params = val.is_a?(Hash) ? ActionController::Parameters.new(val) : val
    @_params = val.is_a?(Hash) ? WeakParameters.new(val) : val
  end
end

if CANVAS_RAILS3
  module ActiveModel
    ForbiddenAttributesError = ForbiddenAttributes
  end
end

# completely ignore attr_accessible if it's a strong parameters
module ForbiddenAttributesProtectionWithoutAttrAccessible
  module ClassMethods
    def strong_params
      @strong_params = true
    end

    def strong_params?
      !!@strong_params
    end
  end

  def sanitize_for_mass_assignment(*options)
    new_attributes = options.first
    if new_attributes.respond_to?(:permitted?)
      raise ActiveModel::ForbiddenAttributesError unless new_attributes.permitted?
      new_attributes
    elsif new_attributes.is_a?(WeakParameters) && self.class.strong_params?
      raise ActiveModel::ForbiddenAttributesError
    else
      super
    end
  end
end

ActiveRecord::Base.include(ForbiddenAttributesProtectionWithoutAttrAccessible)
ActiveRecord::Base.singleton_class.include(ForbiddenAttributesProtectionWithoutAttrAccessible::ClassMethods)

ActionController::ParameterMissing.class_eval do
  def skip_error_report?; true; end
end
