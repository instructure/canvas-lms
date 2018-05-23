#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'

class GlobalGrades
  class << self
    include SeleniumDependencies

    def grading_period_dropdown(course)
      f('.grading_periods_selector', course)
    end

    def score(course)
      f('.percent', course)
    end

    def course_link(course)
      fxpath("//a[text()='#{course.name}']")
    end

    def select_grading_period(course, grading_period)
      selected_course = course_row(course)
      click_option(grading_period_dropdown(selected_course), grading_period)
    end

    def get_score_for_course(course)
      selected_course = course_row(course)
      score(selected_course).text
    end

    def course_row(course)
      f('.course_details')
      courses = ff('tr')
      courses.each do |single_course|
        if f('.course a', single_course).text == course.name
          return single_course
        end
      end
      nil
    end

    def visit
      get '/grades'
    end

    def click_course_link(course)
      course_link(course).click
    end
  end
end
