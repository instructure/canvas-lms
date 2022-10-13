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

class CoursePacing::PaceServiceFactory
  def self.for(paceable_context)
    case paceable_context
    when Course
      CoursePacing::CoursePaceService
    when CourseSection
      CoursePacing::SectionPaceService
    when StudentEnrollment
      CoursePacing::StudentEnrollmentPaceService
    else
      Canvas::Errors.capture_exception(
        :pace_service_factory,
        "Expected an object of type 'Course', 'CourseSection', or 'StudentEnrollment', got #{paceable_context.class}: '#{paceable_context}'"
      )
    end
  end
end
