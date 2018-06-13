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

    def score(course)
      f('.percent', course_row(course))
    end

    def grading_period_dropdown(course)
      f('.grading_periods_selector', course)
    end

    def course_link(course)
      fxpath("//a[text()='#{course.name}']")
    end

    def course_details
      f('.course_details')
    end

    def select_grading_period(course, grading_period)
      selected_course = course_row(course)
      click_option(grading_period_dropdown(selected_course), grading_period)
      wait_for_ajaximations
    end

    def get_score_for_course(course)
      score(course).text.split("\n")[0]
    end

    def get_score_for_course_no_percent(course)
      get_score_for_course(course).split("%")[0].to_f
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

    def report(course)
      f('.report',course_row(course))
    end

    def click_report_link(course)
      fln("Student Interactions Report", report(course)).click
    end
  end
end
