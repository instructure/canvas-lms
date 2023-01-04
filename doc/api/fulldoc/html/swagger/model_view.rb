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
#

require "hash_view"

class ModelView < HashView
  attr_reader :name, :properties, :description, :required

  def initialize(name, properties, description = "", required = [], deprecated: false, deprecation_description: "")
    super()
    @name = name
    @properties = properties
    @description = description
    @required = required
    @deprecated = deprecated
    @deprecation_description = deprecation_description
  end

  def self.new_from_model(model)
    lines = model.text.lines.to_a
    json = JSON.parse(lines[1..].join)

    new(
      lines[0].strip,
      json["properties"],
      json["description"] || "",
      json["required"] || [],
      deprecated: json["deprecated"],
      deprecation_description: json["deprecation_description"]
    )
  end

  def deprecated?
    !!@deprecated
  end

  def json_schema
    {
      name => {
        "id" => name,
        "description" => description,
        "required" => required,
        "deprecated" => deprecated?,
        "deprecation_description" => format(@deprecation_description),
        "properties" => properties
      }
    }
  end
end
