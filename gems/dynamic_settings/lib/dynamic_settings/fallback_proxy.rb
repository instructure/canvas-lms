# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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
module DynamicSettings
  class FallbackProxy
    attr_reader :data

    def initialize(data = nil)
      @data = (data || {}).with_indifferent_access
    end

    def fetch(key, **_)
      # use .to_s, to act like consul where booleans aren't
      # first class data types
      @data[key]&.to_s
    end
    alias [] fetch

    # Set multiple key value pairs
    #
    # @param kvs [Hash] Key value pairs where the hash key is the key
    #   and the hash value is the value
    # @param global [nil] Has no effect
    # @return [Hash]
    def set_keys(kvs, global: nil)
      @data.merge!(kvs)
    end

    def for_prefix(prefix_extension, **_)
      self.class.new(@data[prefix_extension])
    end
  end
end
