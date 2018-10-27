require 'active_model'

module LtiAdvantage
  class TypeValidator < ActiveModel::Validator
    def validate(record)
      record.instance_variables.each do |v|
        value = record.instance_variable_get(v)
        attr = v.to_s[1..-1].to_sym

        # verify the value is of the correct type
        validate_type(attr, value, record)

        # verify the value itself is valid
        validate_nested_models(attr, value, record)
      end
    end

    private

    def validate_type(attr, value, record)
      expected_type = record.class::TYPED_ATTRIBUTES[attr]
      return if value.nil? || expected_type.nil?
      return if value.instance_of? expected_type
      record.errors.add(attr, "#{attr} must be an instance of #{expected_type}")
    end

    def validate_nested_models(attr, value, record)
      return validate_nested_array(attr, value, record) if value.instance_of? Array
      return unless value.respond_to?(:invalid?)
      record.errors.add(attr, value.errors) if value.invalid?
    end

    def validate_nested_array(attr, value, record)
      value.each { |v| validate_nested_models(attr, v, record) }
    end
  end
end
