# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "ostruct"

class OpenStruct
  def as_json(*)
    table
  end
end

class OpenObject < OpenStruct
  attr_accessor :object_type

  def self.build(type, data = {})
    res = OpenObject.new(data)
    res.object_type = type
    res
  end

  def id
    table[:id]
  end

  def asset_string
    return table[:asset_string] if table[:asset_string]
    return nil unless type && id

    "#{type.underscore}_#{id}"
  end

  def as_json(options = {})
    object_type ? { object_type => super } : super
  end

  def self.process(pre = {})
    pre = pre.dup
    if pre.is_a? Array
      new_list = pre.map do |obj|
        OpenObject.process(obj)
      end
    elsif pre
      pre.each do |name, value|
        case value
        when Array
          new_list = value.map do |obj|
            if obj.is_a? Hash
              OpenObject.process(obj)
            else
              obj
            end
          end
          pre[name] = new_list
        when Hash
          pre[name] = OpenObject.process(value)
        end
      end
      OpenObject.new(pre)
    end
  end
end
