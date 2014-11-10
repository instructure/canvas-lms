# default to *non* strong parameters
ActionController::Base.class_eval do
  def params
    @_params ||= request.parameters
  end

  def strong_params
    @_strong_params ||= ActionController::Parameters.new(request.parameters)
  end

  def params=(val)
    @_strong_params = val.is_a?(Hash) ? ActionController::Parameters.new(val) : val
    @_params = val
  end
end

# completely ignore attr_accessible if it's a strong parameters
module ForbiddenAttributesProtectionWithoutAttrAccessible
  def sanitize_for_mass_assignment(*options)
    new_attributes = options.first
    if new_attributes.respond_to?(:permitted?)
      raise ActiveModel::ForbiddenAttributes unless new_attributes.permitted?
      new_attributes
    else
      super
    end
  end
end

ActiveRecord::Base.send(:include, ForbiddenAttributesProtectionWithoutAttrAccessible)

ActionController::ParameterMissing.class_eval do
  def skip_error_report?; true; end
end
