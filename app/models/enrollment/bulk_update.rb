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
class Enrollment::BulkUpdate
  include Api

  DEFAULT_ENROLLMENT = {
    type: "StudentEnrollment",
    no_notify: false,
  }.freeze

  def initialize(context, user)
    @context = context
    @current_user = user
  end

  def bulk_enrollment(progress = nil, user_ids:, course_ids:)
    progress&.calculate_completion!(0, user_ids.size * course_ids.size)
    errors = {}
    users = api_find_all(User, user_ids, account: @context)
    courses = api_find_all(Course, course_ids, account: @context)
    users.each do |user|
      courses.each do |course|
        unless user.can_be_enrolled_in_course?(course)
          errors[user.id] << "User #{user.id} cannot be enrolled in course #{course.id}"
        end

        SubmissionLifecycleManager.with_executing_user(@current_user) do
          @enrollment = course.enroll_user(user, DEFAULT_ENROLLMENT[:type], DEFAULT_ENROLLMENT.to_h.merge(allow_multiple_enrollments: true))
        end
        errors[user.id] << @enrollment.errors unless @enrollment.valid?
      rescue => e
        errors[user.id] = "Error processing user #{user.id}: #{e.message}"
      ensure
        progress&.increment_completion!(1) if progress&.total
      end
    end
    progress&.set_results(errors:)
    progress&.complete!
  end
end
