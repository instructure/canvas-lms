# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

# This utility was built to enable us to compare settings hashes on context external
# tools for deduping purposes. It supports various levels of hash nesting with arrays,
# hashes or other keys for comparison with other hashes. Keys on context external tools
# are usually symbols or strings, but this should support more complicated keys as well.

# WARNING: This DOES sort array data, since some of our external tools have arrays of
# hash data that needs to be ordered for comparison. It also curently sorts all
# non-array/hash items as strings.
module Utils
  class HashUtils
    def self.sort_nested_data(data)
      case data
      when Hash
        data.map { |key, value| [sort_nested_data(key), sort_nested_data(value)] }.sort
      when Array
        data.map { |item| sort_nested_data(item) }.sort
      else
        data.to_s
      end
    end
  end
end
