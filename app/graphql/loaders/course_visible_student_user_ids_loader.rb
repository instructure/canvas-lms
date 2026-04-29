# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# Loader for fetching visible student user IDs for courses.
#
# Performance Improvement:
# Gradebook uses GraphQL aliases to fetch submissions for multiple students within
# a single course. This previously triggered N enrollment queries (one per alias),
# even though the course_id remained constant. By moving this calculation to an async
# loader, queries are limited to 1 per course. For Gradebook's typical use case
# (single course, multiple students), this reduces N queries to 1. For other use cases
# with multiple courses, the query count remains the same or better (old >= new).
class Loaders::CourseVisibleStudentUserIdsLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    super()
    @current_user = current_user
  end

  def perform(courses)
    return if courses.empty? || @current_user.nil?

    courses.each do |course|
      visible_user_ids = course.apply_enrollment_visibility(course.all_student_enrollments, @current_user).pluck(:user_id)
      fulfill(course, visible_user_ids)
    end
  end
end
