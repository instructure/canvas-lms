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
    assignments_by_course_id = Assignment.where(id: assignment_ids).group_by(&:context_id)

    courses_by_id = Course.where(id: assignments_by_course_id.keys).index_by(&:id)

    data = {}
    assignments_by_course_id.each do |course_id, assignments|
      course = courses_by_id[course_id]

      course_visibility_data = AssignmentVisibility::AssignmentVisibilityService.assignments_with_user_visibilities(
        course,
        assignments
      )
      data.merge!(course_visibility_data)
    end

    assignment_ids.each do |id|
      fulfill(id, data.fetch(id, []))
    end
  end
end
