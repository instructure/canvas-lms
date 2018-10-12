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

module NewCourseSearchPage

  # ---------------------- Page ----------------------
  def visit_courses(account)
    get("/accounts/#{account.id}/")
    wait_for_ajaximations
  end

  def visit_users(account)
    get("/accounts/#{account.id}/users")
    wait_for_ajaximations
  end

  # ---------------------- Controls ----------------------
  def add_user_button(course_name)
    fj("[data-automation='courses list'] tr:contains('#{course_name}') button:has([name='IconPlus'])")
  end

  def course_teacher_link(teacher)
    ff("[data-automation='courses list'] tr").first.find("a[href='#{user_url(teacher)}']")
  end

  def course_page_link(course_name)
    fj("[data-automation='courses list'] tr a:contains(#{course_name})")
  end

  def course_search_box
    f('input[placeholder="Search courses..."]')
  end

  def results_body
    f('#content')
  end

  def results_list_css
    "[data-automation='courses list'] tr"
  end

  def left_navigation
    f('#left-side #section-tabs')
  end

  def results_row_css
    '[data-automation="courses list"] tr'
  end

  def results_rows
    ff(results_row_css)
  end

  def hide_courses_without_students
    fj('label:contains("Hide courses without students")')
  end

  # ---------------------- Actions ----------------------
  def click_add_user_button(course_name)
    add_user_button(course_name).click
  end

  def enter_search(search_name)
    set_value(course_search_box, search_name)
    driver.action.send_keys(:enter).perform
    wait_for_ajaximations
  end

  def click_course_link(course_name)
    course_page_link(course_name).click
  end

  def click_hide_courses_without_students
    hide_courses_without_students.click
  end
end
