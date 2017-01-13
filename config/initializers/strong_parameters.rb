class WeakParameters < ActiveSupport::HashWithIndifferentAccess
  # i think we might have to leave this in for future YAML parsing :/
end

module ArbitraryStrongishParams
  ANYTHING = Object.new.freeze

  def initialize(attributes = (CANVAS_RAILS4_2 ? nil : {}))
    @anythings = {}.with_indifferent_access
    super
  end

  def encode_with(_coder)
    raise "Strong parameters should not be dumped to YAML"
  end

  # this is mostly copy-pasted
  def hash_filter(params, filter)
    filter = filter.with_indifferent_access

    # Slicing filters out non-declared keys.
    slice(*filter.keys).each do |key, value|
      next unless value

      if filter[key] == ActionController::Parameters::EMPTY_ARRAY
        # Declaration { comment_ids: [] }.
        array_of_permitted_scalars_filter(params, key)
      elsif filter[key] == ANYTHING
        if filtered = recursive_arbitrary_filter(value)
          params[key] = filtered
          params.instance_variable_get(:@anythings)[key] = true
        end
      else
        # Declaration { user: :name } or { user: [:name, :age, { address: ... }] }.
        params[key] = each_element(value) do |element|
          if element.is_a?(Hash)
            element = self.class.new(element) unless element.respond_to?(:permit)
            element.permit(*Array.wrap(filter[key]))
          end
        end
      end
    end
  end

  def recursive_arbitrary_filter(value)
    if value.is_a?(Hash)
      hash = {}
      value.each do |k, v|
        hash[k] = recursive_arbitrary_filter(v) if permitted_scalar?(k)
      end
      hash
    elsif value.is_a?(Array)
      arr = []
      value.each do |v|
        if permitted_scalar?(v)
          arr << v
        elsif filtered = recursive_arbitrary_filter(v)
          arr << filtered
        end
      end
      arr
    elsif permitted_scalar?(value)
      value
    end
  end

  def convert_hashes_to_parameters(key, value, *args)
    return value if @anythings.key?(key)
    super
  end

  def dup
    super.tap do |duplicate|
      duplicate.instance_variable_set(:@anythings, @anythings.dup)
    end
  end
end
ActionController::Parameters.prepend(ArbitraryStrongishParams)

ActionController::Base.class_eval do
  def strong_anything
    ArbitraryStrongishParams::ANYTHING
  end
end

ActionController::ParameterMissing.class_eval do
  def skip_error_report?; true; end
end
