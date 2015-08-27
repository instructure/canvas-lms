#
# Copyright (C) 2015 Instructure, Inc.
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

class GradingPeriod
  class CourseGradingPeriodFinder

    def initialize(course)
      @course = course
    end

    def grading_periods
      course_gps = GradingPeriod.active.grading_periods_by(course_id: course.id)
      course_gps.present? ?
        course_gps :
        AccountGradingPeriodFinder.new(course.account).grading_periods
    end

    private
    attr_reader :course
  end
end
