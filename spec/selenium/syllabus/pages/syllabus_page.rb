# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module CourseSyllabusPage
  #------------------------------ Selectors -----------------------------

  def show_summary_chkbox_css
    "#course_syllabus_course_summary"
  end

  def syllabus_container_css
    "#syllabusContainer"
  end

  def mini_calendar_css
    "div.mini_month"
  end

  def mini_calendar_first_day_of_month_number_selector
    "div.mini_month table tbody tr:first-child td:first-child .day_number"
  end

  def mini_calendar_first_day_of_month_label_selector
    "div.mini_month table tbody tr:first-child td:first-child span.screenreader-only:first-child"
  end

  def mini_calendar_next_month_button_selector
    "div.mini_month .next_month_link"
  end

  def course_pacing_notice_selector
    "[data-testid='CoursePacingNotice']"
  end

  def immersive_reader_css
    "#immersive_reader_mount_point [type='button']"
  end

  #------------------------------ Elements ------------------------------
  def edit_syllabus_button
    f("button.edit_syllabus_link")
  end

  def show_course_summary_input
    f("label[for='course_syllabus_course_summary']")
  end

  def course_summary_header
    fj("h2:contains(Course Summary:)")
  end

  def syllabus_container
    f(syllabus_container_css)
  end

  def mini_calendar
    f(mini_calendar_css)
  end

  def page_main_content
    f("#not_right_side")
  end

  def update_syllabus_button
    fj("button:contains('Update Syllabus')")
  end

  def show_course_summary_checkbox
    f("#course_syllabus_course_summary")
  end

  def mini_calendar_first_day_of_month_number
    f(mini_calendar_first_day_of_month_number_selector)
  end

  def mini_calendar_next_month_button
    f(mini_calendar_next_month_button_selector)
  end

  def mini_calendar_first_day_of_month_label
    f(mini_calendar_first_day_of_month_label_selector)
  end

  def course_pacing_notice
    f(course_pacing_notice_selector)
  end

  def immersive_reader_btn
    fj(immersive_reader_css)
  end

  #------------------------------ Actions -------------------------------

  def visit_syllabus_page(course_id)
    get "/courses/#{course_id}/assignments/syllabus"
  end
end
