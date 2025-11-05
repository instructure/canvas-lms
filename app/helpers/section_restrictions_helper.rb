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

  # Get section IDs where the user is enrolled as teacher/TA
  def get_teacher_section_ids(course, user)
    course.enrollments
          .where(user:, type: ["TeacherEnrollment", "TaEnrollment"])
          .pluck(:course_section_id)
  end

  def get_students_in_teacher_sections(course, user)
    teacher_section_ids = get_teacher_section_ids(course, user)

    course.enrollments
          .where(course_section_id: teacher_section_ids,
                 type: ["StudentEnrollment", "StudentViewEnrollment"])
          .pluck(:user_id)
  end
end
