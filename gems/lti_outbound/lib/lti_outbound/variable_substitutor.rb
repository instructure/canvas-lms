#
# Copyright (C) 2013 Instructure, Inc.
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

module LtiOutbound
  class VariableSubstitutor
    attr_accessor :substitutions

    attr_reader :substitution_objects

    def initialize()
      self.substitutions = {}
    end

    def add_substitution(key, value)
      substitutions[key] = value
    end

    def substitute!(data_hash)
      data_hash.each do |k, v|
        if value = substitution_value(v)
          data_hash[k] = value
        end
      end
      data_hash
    end

    def has_key?(key)
      substitutions.has_key? key
    end

    private

    def substitution_value(key)
      value = substitutions[key]
      if value.is_a?(Proc)
        value = value.call
        substitutions[key] = value
      end
      value
    end

  end
end