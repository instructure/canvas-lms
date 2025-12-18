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

class Loaders::ObservedStudentsLoader < GraphQL::Batch::Loader
  def initialize(current_user:, include_restricted_access: false)
    super()
    @current_user = current_user
    @include_restricted_access = include_restricted_access
  end

  def perform(courses)
    return courses.each { |course| fulfill(course, {}) } unless @current_user

    course_ids = courses.map(&:id)

    observer_enrollments = ObserverEnrollment
                           .where(course_id: course_ids, user_id: @current_user)
                           .where.not(associated_user_id: nil)

    associated_user_ids = observer_enrollments.pluck(:associated_user_id).uniq
    return courses.each { |course| fulfill(course, {}) } if associated_user_ids.empty?

    students_query = Enrollment
                     .joins(:enrollment_state)
                     .where(
                       course_id: course_ids,
                       user_id: associated_user_ids,
                       type: %w[StudentEnrollment StudentViewEnrollment]
                     )
                     .where.not(workflow_state: %w[rejected completed deleted inactive])

    unless @include_restricted_access
      students_query = students_query.where(enrollment_states: { restricted_access: false })
    end

    students_by_course = students_query.preload(:user).group_by(&:course_id)

    courses.each do |course|
      enrollments = students_by_course[course.id] || []
      students_hash = enrollments.group_by(&:user)
      fulfill(course, students_hash)
    end
  end
end
