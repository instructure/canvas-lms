#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class WeakParameters < ActiveSupport::HashWithIndifferentAccess
  # i think we might have to leave this in for future YAML parsing :/
end

module ArbitraryStrongishParams
  ANYTHING = Object.new.freeze

  def initialize(attributes = {})
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
        array_of_permitted_scalars?(self[key]) do |val|
          params[key] = val
        end
      elsif filter[key] == ANYTHING
        if filtered = recursive_arbitrary_filter(value)
          params[key] = filtered
          params.instance_variable_get(:@anythings)[key] = true
        end
      else
        # Declaration { user: :name } or { user: [:name, :age, { address: ... }] }.
        params[key] = each_element(value) do |element|
          if element.is_a?(Hash) || element.is_a?(ActionController::Parameters)
            element = self.class.new(element) unless element.respond_to?(:permit)
            element.permit(*Array.wrap(filter[key]))
          end
        end
      end
    end
  end

  def recursive_arbitrary_filter(value)
    if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
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
