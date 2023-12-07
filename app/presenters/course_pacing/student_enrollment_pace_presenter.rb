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

class CoursePacing::StudentEnrollmentPacePresenter < CoursePacing::PacePresenter
  attr_reader :student_enrollment

  def initialize(student_enrollment_pace, student_enrollment = nil)
    super(student_enrollment_pace)
    @student_enrollment = student_enrollment || @pace.user.enrollments.find_by(course_id: @pace.course)
  end

  def as_json
    default_json.merge({
                         student: {
                           name: student_enrollment.user.name,
                         }
                       })
  end

  private

  def context_id
    @student_enrollment.id
  end

  def context_type
    "StudentEnrollment"
  end
end
