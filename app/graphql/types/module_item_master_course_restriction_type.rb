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
  class ModuleItemMasterCourseRestrictionType < ApplicationObjectType
    description "Restrictions for a module item defined in a blueprint course"

    field :all, Boolean, null: true, description: "Whether all aspects are restricted"
    field :availability_dates, Boolean, null: true, description: "Whether availability dates are restricted", camelize: true
    field :content, Boolean, null: true, description: "Whether content is restricted"
    field :due_dates, Boolean, null: true, description: "Whether due dates are restricted", camelize: true
    field :points, Boolean, null: true, description: "Whether points are restricted"
    field :settings, Boolean, null: true, description: "Whether settings are restricted"
  end
end
