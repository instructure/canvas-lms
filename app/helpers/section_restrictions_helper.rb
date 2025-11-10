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

module SectionRestrictionsHelper
  # Check if the given user has section restrictions in the given course
  def user_has_section_restrictions?(course, user)
    return false unless course.is_a?(Course) && user

    enrollment = course.membership_for_user(user)
    return false unless enrollment

    enrollment.limit_privileges_to_course_section?
  end

  def get_user_section_ids(course, user)
    course.enrollments
          .active_or_pending
          .where(user:)
          .pluck(:course_section_id)
  end

  def get_visible_student_ids_in_course(course, user)
    user_section_ids = get_user_section_ids(course, user)

    course.enrollments
          .where(course_section_id: user_section_ids,
                 type: ["StudentEnrollment", "StudentViewEnrollment"])
          .pluck(:user_id)
  end
end
