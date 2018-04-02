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
#

require 'hash_view'

class ReturnViewNull < HashView
  def array?; false; end

  def type; nil; end

  def to_hash
    {
      "array" => array?,
      "type" => format(type),
    }
  end

  def to_swagger
    {
      "type" => "void"
    }
  end
end

class ReturnView < ReturnViewNull
  def initialize(line)
    if line
      @line = line.gsub(/\s+/m, " ").strip
    else
      raise "@return type required"
    end
  end

  def array?
    @line.include?('[') && @line.include?(']')
  end

  def type
    @line.gsub('[', '').gsub(']', '')
  end

  def to_swagger
    if array? and type
      {
        "type" => "array",
        "items" => {
          "$ref" => type
        }
      }
    else
      {
        "type" => type
      }
    end
  end
end