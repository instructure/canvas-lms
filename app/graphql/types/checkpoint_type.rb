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

    field :points_possible,
          Float,
          "the checkpoint is out of this many points",
          null: false

    field :due_at,
          DateTimeType,
          "when this checkpoint is due for 'Everyone'",
          null: true

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
