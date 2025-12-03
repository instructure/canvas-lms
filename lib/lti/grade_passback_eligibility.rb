# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Lti
  module GradePassbackEligibility
    def grade_passback_allowed?(course, user)
      return true unless course_concluded?(course)
      return true if user_enrollment_active?(course, user)

      false
    end

    def course_concluded?(course)
      course.completed? || course.soft_concluded_for_all?(["TeacherEnrollment", "TaEnrollment"])
    end

    private

    # Check if the user has an active or pending course or section enrollment in the course.
    def user_enrollment_active?(course, user)
      course.student_enrollments.where(user_id: user).active_or_pending_by_date.any?
    end
  end
end
