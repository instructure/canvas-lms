# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Types
  class PlacementType < GraphQL::Schema::Object
    field :title, String, null: false
    field :url, String, null: false
  end

  class Placements < Types::PlacementType
    description "A placement for an external tool in Canvas"

    field :assignment_selection, PlacementType, null: true, description: "Placement for assignment selection"
    field :course_assignments_menu, PlacementType, null: true, description: "Placement for course assignments menu"
    field :editor_button, PlacementType, null: true, description: "Placement for editor button"
    field :link_selection, PlacementType, null: true, description: "Placement for link selection"
    field :module_index_menu_modal, PlacementType, null: true, description: "Placement for module index menu modal"
    field :module_menu_modal, PlacementType, null: true, description: "Placement for module menu modal"
    field :resource_selection, PlacementType, null: true, description: "Placement for resource selection"
  end
end

module Interfaces
  module PlacementsInterface
    include GraphQL::Schema::Interface

    description "Interface for placements"

    field :placements, Types::Placements, null: false, description: "Placements for the external tool"

    def placements
      placements_obj = {}
      object.context_external_tool_placements.each do |placement|
        placement_type = placement.placement_type.to_sym
        placement_data = {
          title: object.label_for(placement_type, I18n.locale),
          url: object.extension_setting(placement_type, :url) ||
               object.extension_default_value(placement_type, :url) ||
               object.extension_default_value(placement_type, :target_link_uri)
        }
        placements_obj[placement_type] = placement_data
      end
      placements_obj
    end
  end
end
