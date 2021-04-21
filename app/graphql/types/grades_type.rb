# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
  class GradesType < ApplicationObjectType
    graphql_name "Grades"

    description "Contains grade information for a course or grading period"

    class GradeState < BaseEnum
      graphql_name "GradeState"
      value "active"
      value "deleted"
    end

    field :current_score, Float, <<~DESC, null: true
      The current score includes all graded assignments, excluding muted submissions.
    DESC
    field :unposted_current_score, Float, <<~DESC, null: true
      The current score includes all graded assignments, including muted submissions.
    DESC
    field :current_grade, String, null: true
    field :unposted_current_grade, String, null: true

    field :final_score, Float, <<~DESC, null: true
      The final score includes all assignments, excluding muted submissions
      (ungraded assignments are counted as 0 points).
    DESC
    field :unposted_final_score, Float, <<~DESC, null: true
      The final score includes all assignments, including muted submissions
      (ungraded assignments are counted as 0 points).
    DESC
    field :final_grade, String, null: true
    field :unposted_final_grade, String, null: true

    field :override_score, Float, <<~DESC, null: true
      The override score. Supersedes the computed final score if set.
    DESC

    field :override_grade, String, <<~DESC, null: true
      The override grade. Supersedes the computed final grade if set.
    DESC
    def override_grade
      return nil if object.override_score.blank?
      object.effective_final_grade
    end

    field :grading_period, GradingPeriodType, null: true
    def grading_period
      load_association :grading_period
    end

    field :state, GradeState, method: :workflow_state, null: false

    field :assignment_group, AssignmentGroupType, null: true
    def assignment_group
      load_association(:assignment_group)
    end

    field :enrollment, EnrollmentType, null: true
    def enrollment
      load_association(:enrollment)
    end

  end
end
