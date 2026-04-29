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
  def perform(assignments)
    courses_by_id = Course.where(id: assignments.map(&:context_id).uniq).index_by(&:id)

    data = {}
    assignments.group_by(&:context_id).each do |course_id, course_assignments|
      course = courses_by_id[course_id]

      course_visibility_data = AssignmentVisibility::AssignmentVisibilityService.assignments_with_user_visibilities(
        course,
        course_assignments
      )
      data.merge!(course_visibility_data)
    end

    assignments.each do |assignment|
      fulfill(assignment, data.fetch(assignment.id, []))
    end
  end
end
