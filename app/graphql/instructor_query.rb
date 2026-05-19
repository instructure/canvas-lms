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

InstructorWithEnrollments = Struct.new(:user, :enrollments)
InstructorEnrollmentInfo = Struct.new(:course, :type, :role, :state)

class InstructorQuery
  def initialize(deduplicated_ids_subquery)
    @deduplicated_ids_subquery = deduplicated_ids_subquery
  end

  def total_count
    @total_count ||= Enrollment
                     .where(id: @deduplicated_ids_subquery)
                     .distinct
                     .count(:user_id)
  end

  alias_method :count, :total_count

  def fetch_page(limit, offset)
    grouped_results = Enrollment
                      .joins(:user, :course, :role)
                      .where(id: @deduplicated_ids_subquery)
                      .group("users.id, users.sortable_name")
                      .order("users.sortable_name ASC")
                      .offset(offset)
                      .limit(limit)
                      .pluck(
                        Arel.sql("users.id"),
                        Arel.sql("json_agg(json_build_object(
                          'course_id', courses.id,
                          'type', enrollments.type,
                          'role_id', roles.id,
                          'state', enrollments.workflow_state
                        ) ORDER BY courses.name)")
                      )

    return [] if grouped_results.empty?

    user_ids = grouped_results.map(&:first)
    all_enrollment_data = grouped_results.flat_map { |_, json| json }
    course_ids_needed = all_enrollment_data.pluck("course_id").uniq
    role_ids_needed = all_enrollment_data.pluck("role_id").uniq

    users_by_id = User.where(id: user_ids).index_by(&:id)
    courses_by_id = Course.where(id: course_ids_needed).index_by(&:id)
    roles_by_id = Role.where(id: role_ids_needed).index_by(&:id)

    grouped_results.map do |user_id, enrollments_data|
      InstructorWithEnrollments.new(
        user: users_by_id[user_id],
        enrollments: enrollments_data.map do |e|
          InstructorEnrollmentInfo.new(
            course: courses_by_id[e["course_id"]],
            type: e["type"],
            role: roles_by_id[e["role_id"]],
            state: e["state"]
          )
        end
      )
    end
  end
end
