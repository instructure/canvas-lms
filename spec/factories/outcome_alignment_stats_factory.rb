# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module Factories
  def outcome_alignment_stats_model
    course_model
    @outcome1 = outcome_model(context: @course, title: "outcome 1 - aligned")
    @outcome2 = outcome_model(context: @course, title: "outcome 2 - not aligned")
    @assignment1 = @course.assignments.create!(title: "assignment 1 - aligned")
    @assignment2 = @course.assignments.create!(title: "assignment 2 - aligned")
    @assignment3 = @course.assignments.create!(title: "assignment 3 - not aligned")
    @assignment4 = @course.assignments.create!(title: "assignment 4 - not aligned")
    outcome_with_rubric(outcome: @outcome1)
    @rubric.associate_with(@assignment1, @course, purpose: "grading")
    @rubric.associate_with(@assignment2, @course, purpose: "grading")
  end
end
