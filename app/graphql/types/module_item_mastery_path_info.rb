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
  class ModuleItemMasteryPathInfo < ApplicationObjectType
    description "Mastery path information for a module item"

    field :assignment_set_count, Integer, null: true, description: "Number of assignment sets that can be selected", camelize: true
    field :awaiting_choice, Boolean, null: true, description: "Whether the next assignment set can be chosen", camelize: true
    field :choose_url, String, null: true, description: "URL to expose next assignment set choice", camelize: true
    field :locked, Boolean, null: true, description: "Indicates locked content"
    field :still_processing, Boolean, null: true, description: "Indicates mastery path handler in-flight", camelize: true
    def assignment_set_count
      object[:assignment_sets].count
    end
  end
end
