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

    field :current_score, Float, <<~DESC, null: true
      The current score includes all graded assignments
    DESC
    field :current_grade, String, null: true

    field :final_score, Float, <<~DESC, null: true
      The final score includes all assignments
      (ungraded assignments are counted as 0 points)
    DESC
    field :final_grade, String, null: true

    field :grading_period, GradingPeriodType, null: true
    def grading_period
      load_association :grading_period
    end
  end
end
