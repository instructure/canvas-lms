# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module I18nTasks
  module Utils
    CORE_KEYS = %i[date time number datetime support].freeze

    # From https://stackoverflow.com/questions/4364891
    def self.flat_keys_to_nested(hash)
      hash.each_with_object({}) do |(key,value), all|
        key_parts = key.split('.').map!(&:to_sym)
        leaf = key_parts[0...-1].inject(all) { |h, k| h[k] ||= {} }
        leaf[key_parts.last] = value
      end
    end

    def self.partition_hash(hash)
      true_hash = {}
      false_hash = {}

      hash.each_with_object([true_hash, false_hash]) { |(k, v), (true_hash, false_hash)|
        yield(k, v) ? true_hash[k] = v : false_hash[k] = v
      }

      [true_hash, false_hash]
    end
  end
end
