# frozen_string_literal: true

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
require_relative "../../common"
require_relative "new_course_add_people_modal"
require_relative "new_course_add_course_modal"

module NewCourseSearchPage
  include NewCourseAddPeopleModal
  include NewCourseAddCourseModal

  # ---------------------- Page ----------------------
  def visit_courses(account)
    get("/accounts/#{account.id}/")
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
    f("#content")
  end

  def results_list_css
    "[data-automation='courses list'] tr"
  end

  def left_navigation
    f("#left-side #section-tabs")
  end

  def rows
    ff('[data-automation="courses list"] tr')
  end

  def hide_course_without_students_checkbox
    fj('label:contains("Hide courses without students")')
  end

  def course_table
    f('[data-automation="courses list"]')
  end

  def course_table_navigation
    f('#content [role="navigation"]')
  end

  def table_nav_buttons(page_number)
    fj("nav button:contains(#{page_number})")
  end

  def search_text_box
    f('input[placeholder="Search courses..."]')
  end

  def add_course_button
    fj('button:has([name="IconPlus"]):contains("Course")')
  end

  # ---------------------- Actions ----------------------
  def click_add_user_button(course_name)
    add_user_button(course_name).click
  end

  def click_course_link(course_name)
    course_page_link(course_name).click
  end

  def click_hide_courses_without_students
    wait_for_spinner { hide_course_without_students_checkbox.click }
  end

  def navigate_to_page(page_number)
    wait_for_new_page_load { table_nav_buttons(page_number).click }
  end

  def select_term(term)
    wait_for_spinner { click_INSTUI_Select_option("#termFilter", term.name) }
  end

  def search(search_text)
    wait_for_spinner { search_text_box.send_keys(search_text) }
  end

  def click_add_users_to_course(course)
    row = rows.first { |e| e.text contains(course.name) }
    fj('button:contains("Add Users to Unnamed Course")', row).click
    add_people_modal
    wait_for_ajaximations
  end

  def click_add_course_button
    add_course_button.click
    add_course_modal
    wait_for_ajaximations
  end

  def wait_for_spinner(&)
    wait_for_transient_element('svg[role="img"] circle', &)
    wait_for_ajaximations
  end
end
