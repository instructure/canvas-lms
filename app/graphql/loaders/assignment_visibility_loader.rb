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
#
#
class Loaders::AssignmentVisibilityLoader < GraphQL::Batch::Loader
  def perform(assignment_ids)
    # 1. Fetch Assignment id and course_id pairs
    assignment_course_pairs = Assignment.where(id: assignment_ids).pluck(:id, :context_id)

    # 2. Group assignments by course_id
    assignments_by_course = assignment_course_pairs.group_by(&:last).transform_values do |pairs|
      pairs.map(&:first)
    end

    # 3. Call visibility calculation for each course and merge results
    data = {}
    assignments_by_course.each do |course_id, course_assignment_ids|
      course_visibility_data = AssignmentVisibility::AssignmentVisibilityService.users_with_visibility_by_assignment(
        course_id:,
        assignment_ids: course_assignment_ids
      )
      data.merge!(course_visibility_data)
    end

    # 4. Fulfill each assignment with its visibility data
    assignment_ids.each do |id|
      fulfill(id, data.fetch(id, []))
    end
  end
end
