# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Types
  class CourseRequirementsType < ApplicationObjectType
    field :completed, Integer, null: false, method: :normalized_requirement_completed_count
    field :completion_percentage, Float, null: false, method: :progress_percent
    field :total, Integer, null: false, method: :normalized_requirement_count
  end

  class ModuleProgressionType < ApplicationObjectType
    field :incomplete_items_connection,
          Types::ModuleItemType.connection_type,
          "Items are ordered by position",
          null: false,
          hash_key: :items
    field :module, Types::ModuleType, null: false
  end

  class CourseProgressionType < ApplicationObjectType
    field :requirements, CourseRequirementsType, null: false
    def requirements
      object
    end

    field :incomplete_modules_connection,
          Types::ModuleProgressionType.connection_type,
          "Modules are ordered by position",
          null: true,
          method: :incomplete_items_for_modules
  end
end
