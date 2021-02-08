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
  module HashExtensions
    def flatten_keys(result={}, prefix='')
      each_pair do |k, v|
        if v.is_a?(Hash)
          v.flatten_keys(result, "#{prefix}#{k}.")
        else
          result["#{prefix}#{k}"] = v
        end
      end
      result
    end

    def expand_keys(result = {})
      each_pair do |k, v|
        parts = k.split('.')
        last = parts.pop
        parts.inject(result) { |h, k2| h[k2] ||= {} }[last] = v
      end
      result
    end

    def to_ordered
      keys.sort_by(&:to_s).inject ActiveSupport::OrderedHash.new do |h, k|
        v = fetch(k)
        h[k] = v.is_a?(Hash) ? v.to_ordered : v
        h
      end
    end

    Hash.send(:include, HashExtensions)
  end
end