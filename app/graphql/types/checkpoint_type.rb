# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
  class CheckpointType < ApplicationObjectType
    alias_method :checkpoint, :object

    field :name, String, null: true

    field :tag,
          String,
          "the tag of the checkpoint",
          null: false
    def tag
      checkpoint.sub_assignment_tag
    end

    def self.overridden_field(field_name, description)
      field field_name, DateTimeType, description, null: true do
        argument :apply_overrides, Boolean, <<~MD, required: false, default_value: true
          When true, return the overridden dates.

          Not all roles have permission to view un-overridden dates (in which
          case the overridden dates will be returned)
        MD
      end

      define_method(field_name) do |apply_overrides:|
        load_association(:context).then do |course|
          if !apply_overrides && course.grants_any_right?(current_user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
            checkpoint.send(field_name)
          else
            # Due to how assigment overrides are caluclated for teachers/admins in self.overrides_for_assignment_and_user,
            # A user with read_as_admin permissions will have this due date overrideen based on all overrides on the assignment.
            # This matches the existing behavior on the Assignment date fields.
            Loaders::OverrideAssignmentLoader.for(current_user).load(checkpoint).then(&field_name)
          end
        end
      end
    end

    overridden_field :due_at, "when this checkpoint is due"
    overridden_field :unlock_at, "when this checkpoint is available"
    overridden_field :lock_at, "when this checkpoint is closed"

    field :points_possible,
          Float,
          "the checkpoint is out of this many points",
          null: false

    field :only_visible_to_overrides,
          Boolean,
          "specifies that this checkpoint is only assigned to students for whom an override applies",
          null: false

    field :assignment_overrides, AssignmentOverrideType.connection_type, null: true
    def assignment_overrides
      AssignmentOverrideApplicator.overrides_for_assignment_and_user(checkpoint, current_user)
    end
  end
end
