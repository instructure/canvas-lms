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
    def grade
      protect_submission_grades(:grade)
    end

    field :score, Float, null: true
    def score
      protect_submission_grades(:score)
    end

    field :assignment_id, ID, null: false

    field :custom_grade_status_id, ID, null: true
    field :seconds_late, Integer, null: true

    field :grade_matches_current_submission, Boolean, null: true

    field :published_score, Float, null: true
    def published_score
      protect_submission_grades(:published_score)
    end

    field :late, Boolean, method: :late?
    field :late_policy_status, LatePolicyStatusType, null: true
    field :missing, Boolean, method: :missing?

    field :published_grade, String, null: true
    def published_grade
      protect_submission_grades(:published_grade)
    end

    field :sub_assignment_tag, String, null: true
    def sub_assignment_tag
      return object.assignment.sub_assignment_tag if object.assignment.is_a?(SubAssignment)

      nil
    end

    field :status_tag, Types::SubmissionStatusTagType, null: false
    def status_tag
      load_association(:assignment).then do
        Loaders::AssociationLoader.for(Assignment, :external_tool_tag).load(object.assignment).then do
          object.status_tag
        end
      end
    end

    field :excused,
          Boolean,
          "excused assignments are ignored when calculating grades",
          method: :excused?,
          null: true

    field :entered_grade,
          String,
          "the submission grade *before* late policy deductions were applied",
          null: true
    def entered_grade
      protect_submission_grades(:entered_grade)
    end

    field :entered_score,
          Float,
          "the submission score *before* late policy deductions were applied",
          null: true
    def entered_score
      protect_submission_grades(:entered_score)
    end

    def protect_submission_grades(attr)
      load_association(:assignment).then do
        object.send(attr) if object.user_can_read_grade?(current_user, session)
      end
    end
    private :protect_submission_grades
  end
end
