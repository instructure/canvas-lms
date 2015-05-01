#
# Copyright (C) 2011 Instructure, Inc.
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

require 'ostruct'

class OpenStruct
  def as_json(options={})
    table
  end
end

class OpenObject < OpenStruct
  attr_accessor :object_type
  def self.build(type, data={})
    res = OpenObject.new(data)
    res.object_type = type
    res
  end

  def id
    self.table[:id]
  end

  def asset_string
    return self.table[:asset_string] if self.table[:asset_string]
    return nil unless self.type && self.id
    "#{self.type.underscore}_#{self.id}"
  end

  def as_json(options={})
    object_type ? {object_type => super} : super
  end

  def self.process(pre={})
    pre = pre.dup
    if pre.is_a? Array
      new_list = []
      pre.each do |obj|
        new_list << OpenObject.process(obj)
      end
      new_list
    elsif pre
      pre.each do |name, value|
        if value.is_a? Array
          new_list = []
          value.each do |obj|
            if obj.is_a? Hash
              new_list << OpenObject.process(obj)
            else
              new_list << obj
            end
          end
          pre[name] = new_list
        elsif value.is_a? Hash
          pre[name] = OpenObject.process(value)
        end
      end
      OpenObject.new(pre)
    end
  end
end
