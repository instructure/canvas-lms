# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

module Types
  class StringMapType < Types::BaseScalar
    description "A hash with string keys and string values"

    def self.coerce_input(input_value, _context)
      return nil if input_value.nil?

      unless input_value.is_a?(Hash) && input_value.all? { |k, v| k.is_a?(String) && v.is_a?(String) }
        raise GraphQL::CoercionError, "#{input_value.inspect} is not a valid StringMap"
      end

      input_value
    end

    def self.coerce_result(ruby_value, _context)
      unless ruby_value.is_a?(Hash) && ruby_value.all? { |k, v| (k.is_a?(Symbol) || k.is_a?(String)) && v.is_a?(String) }
        raise GraphQL::CoercionError, "#{ruby_value.inspect} is not a valid StringMap"
      end

      ruby_value.transform_keys(&:to_s)
    end
  end
end
