# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::StudentEnrollmentPaceService < CoursePacing::PaceServiceInterface
  def self.paces_in_course(course)
    course.course_paces.not_deleted.student_enrollment_paces.preload(:user)
  end

  def self.pace_in_context(student_enrollment)
    paces_in_course(course_for(student_enrollment)).find_by!(user_id: student_enrollment.user_id)
  end

  def self.template_pace_for(student_enrollment)
    if student_enrollment.course_section_id.nil?
      course_for(student_enrollment).course_paces.primary.take
    else
      begin
        CoursePacing::SectionPaceService.pace_in_context(student_enrollment.course_section)
      rescue ActiveRecord::RecordNotFound
        CoursePacing::SectionPaceService.template_pace_for(student_enrollment.course_section)
      end
    end
  end

  def self.create_params(student_enrollment)
    super.merge({ user_id: student_enrollment.user_id })
  end

  def self.course_for(student_enrollment)
    student_enrollment.course
  end
end
