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

class CoursePacing::StudentEnrollmentPacesApiController < CoursePacing::PacesApiController
  private

  def pacing_service
    CoursePacing::StudentEnrollmentPaceService
  end

  def pacing_presenter
    CoursePacing::StudentEnrollmentPacePresenter
  end

  attr_reader :course

  def context
    @student_enrollment
  end

  def load_contexts
    @course = api_find(Course.active, params[:course_id])
    if params[:student_enrollment_id]
      @student_enrollment = @course.student_enrollments.find(params[:student_enrollment_id])
    end
  end
end
