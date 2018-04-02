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
require 'method_view'
require 'object_view'

class ControllerView < HashView
  attr_reader :controller

  def initialize(controller)
    @controller = controller
  end

  def raw_name
    @controller.name.to_s
  end

  def name
    format(raw_name.sub(/controller$/i, '').sub(/api$/i, ''))
  end

  def objects
    @controller.tags(:object).map do |object|
      ObjectView.new(object)
    end
  end

  def models
    @controller.tags(:model).map do |model|
      ModelView.new_from_model(model)
    end
  end

  def desc
    if tag = @controller.tags.find{ |t| t.tag_name == 'API' }
      tag.text
    else
      name
    end
  end

  def raw_methods
    @controller.children.select do |method|
      method.tags.find do |tag|
        tag.tag_name.downcase == "api"
      end && !method.tags.any? do |tag|
        tag.tag_name.downcase == "internal"
      end
    end
  end

  def methods
    raw_methods.map do |method|
      MethodView.new(method)
    end
  end

  def to_hash
    {
      "name" => name,
      "methods" => methods.map{ |m| m.to_hash },
    }
  end
end