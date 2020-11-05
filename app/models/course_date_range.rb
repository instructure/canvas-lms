# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class CourseDateRange
  attr_reader :start_at, :end_at
  def initialize(course)
    valid_date_range(course)
  end

  def valid_date_range(course)
    if course.restrict_enrollments_to_course_dates
      @start_at = {date: course.start_at, date_context: "course"} if course.start_at
      @end_at = {date: course.end_at, date_context: "course"} if course.end_at
    end
    @start_at ||= {date: course.enrollment_term.start_at, date_context: "term"}
    @end_at ||= {date: course.enrollment_term.end_at, date_context: "term"}
  end
end
