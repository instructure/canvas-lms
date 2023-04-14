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
#
module CC::Importer::Canvas
  module BlueprintSettingsConverter
    include CC::Importer

    def convert_blueprint_settings(doc)
      hash = {}
      return hash unless doc

      blueprint_settings = doc.at_css("blueprint_settings")
      hash["use_default_restrictions_by_type"] = get_bool_val(blueprint_settings, "use_default_restrictions_by_type", false)
      hash["restrictions"] = blueprint_settings.css("restrictions > restriction").to_h { |node| convert_restriction(node) }
      hash["restricted_items"] = blueprint_settings.css("restricted_items > item").map { |node| convert_item(node) }

      hash
    end

    def convert_restriction(node)
      h = node.attributes.transform_values(&:value)
      type = h.delete("content_type")
      h = h.transform_values { |v| ::Canvas::Plugin.value_to_boolean(v) }
      [type, h]
    end

    def convert_item(node)
      h = {}
      h["migration_id"] = node["identifierref"]
      h["content_type"], h["restrictions"] = convert_restriction(node.at_css("restriction"))
      h["use_default_restrictions"] = get_bool_val(node, "use_default_restrictions", true)
      h
    end
  end
end
