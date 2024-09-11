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
  class SubAssignmentSubmissionType < ApplicationObjectType
    field :grade, String, null: true

    field :score, Float, null: true

    field :assignment_id, ID, null: false

    field :grade_matches_current_submission, Boolean, null: true

    field :published_score, Float, null: true

    field :published_grade, String, null: true

    field :sub_assignment_tag, String, null: true
    def sub_assignment_tag
      return object.assignment.sub_assignment_tag if object.assignment.is_a?(SubAssignment)

      nil
    end
  end
end
