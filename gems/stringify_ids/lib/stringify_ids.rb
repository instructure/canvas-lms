#
# Copyright (C) 2016 Instructure, Inc.
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

module StringifyIds
  def self.recursively_stringify_ids(value, opts = {})
    case value
    when Hash
      stringify_ids(value, opts)
      value.each_value { |v| recursively_stringify_ids(v, opts) if v.is_a?(Hash) || v.is_a?(Array) }
    when Array
      value.each { |v| recursively_stringify_ids(v, opts) if v.is_a?(Hash) || v.is_a?(Array) }
    end
    value
  end

  def self.stringify_ids(value, opts = {})
    return unless value.is_a?(Hash)
    value.keys.each do |key|
      if key =~ /(^|_)id$/
        # id, foo_id, etc.
        value[key] = stringify_id(value[key], opts)
      elsif key =~ /(^|_)ids$/ && value[key].is_a?(Array)
        # ids, foo_ids, etc.
        value[key].map!{ |id| stringify_id(id, opts) }
      end
    end
  end

  def self.stringify_id(id, opts = {})
    if opts[:reverse]
      id.is_a?(String) ? id.to_i : id
    else
      id.is_a?(Integer) ? id.to_s : id
    end
  end
end
