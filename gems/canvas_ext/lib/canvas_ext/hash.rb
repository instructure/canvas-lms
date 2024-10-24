# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
class Hash
  # Recursively sort the values, when appropriate, in a hash.
  # @return [Hash] A new hash with the values sorted
  def deep_sort_values
    to_h do |k, v|
      if v.is_a?(Hash)
        [k, v.deep_sort_values]
      elsif v.is_a?(Array)
        [k, v.sort]
      else
        [k, v]
      end
    end
  end
end
