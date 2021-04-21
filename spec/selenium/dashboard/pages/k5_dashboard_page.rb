# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module K5PageObject
  #------------------------- Selectors --------------------------
  def enable_homeroom_checkbox_selector
    '#course_homeroom_course'
  end

  def welcome_title_selector
    'h1'
  end

  def homeroom_tab_selector
    '#tab-tab-homeroom'
  end

  def schedule_tab_selector
    '#tab-tab-schedule'
  end

  def grades_tab_selector
    '#tab-tab-grades'
  end

  def resources_tab_selector
    '#tab-tab-resources'
  end

  def course_card_selector(course_title)
    "div[title='#{course_title}']"
  end

  def announcement_on_card_xpath_selector(announcement_title)
    "//div[@class = 'ic-DashboardCard']//span[text() = '#{announcement_title}']"
  end

  def subject_link_selector(subject_title)
    "//a[div[@title = '#{subject_title}']]"
  end

  def items_due_selector(subject_title, due_today_text)
    "//*[@aria-label = '#{subject_title}']//*[text() = '#{due_today_text}']"
  end

  def items_missing_selector(subject_title, number_items_missing)
    "//*[@aria-label = '#{subject_title}']//*[text() = '#{number_items_missing} missing']"
  end

  def today_selector
    "h2 div:contains('Today')"
  end

  def homeroom_course_title_selector(title)
    "h2:contains('#{title}')"
  end

  def announcement_title_selector(announcement_title)
    "h3:contains('#{announcement_title}')"
  end

  def announcement_content_text_selector(content_text)
    "div:contains('#{content_text}')"
  end

  def announcement_button_selector
    "//a[*//. = 'Announcement']"
  end

  def announcement_edit_button_selector
    "a[cursor='pointer']"
  end

  def staff_selector(staff_name)
    "h3:contains('#{staff_name}')"
  end

  def instructor_role_selector(inst_role)
    "//*[@data-automation = 'instructor-role' and text() = '#{inst_role}']"
  end

  def instructor_bio_selector(inst_bio)
    "//*[@data-automation = 'instructor-bio' and text() = '#{inst_bio}']"
  end

  def email_link_selector(email_address)
    "a[href = 'mailto:#{email_address}']"
  end

  def grade_title_selector(title)
    "div:contains('#{title}')"
  end

  def subject_grade_selector(value)
    "//*[@data-automation = 'course_grade' and text() = '#{value}']"
  end

  def grade_progress_bar_selector(value)
    "//*[@role = 'progressbar' and @value = '#{value}']"
  end

  def view_grades_button_selector(course_id)
    "a[href = '/courses/#{course_id}/gradebook']"
  end

  def grading_period_dropdown_selector
    "#grading-period-select"
  end

  def week_date_selector
    "h2 div"
  end

  def previous_week_button_selector
    "//button[.//span[. = 'View previous week']]"
  end

  def next_week_button_selector
    "//button[.//span[. = 'View next week']]"
  end

  def today_button_selector
    "//button[.//span[. = 'Today']]"
  end

  #------------------------- Elements --------------------------

  def enable_homeroom_checkbox
    f(enable_homeroom_checkbox_selector)
  end

  def welcome_title
    f(welcome_title_selector)
  end

  def homeroom_tab
    f(homeroom_tab_selector)
  end

  def schedule_tab
    f(schedule_tab_selector)
  end

  def grades_tab
    f(grades_tab_selector)
  end

  def resources_tab
    f(resources_tab_selector)
  end

  def course_card(course_title)
    f("div[title='#{course_title}']")
  end

  def course_card_announcement(course_title)
    fxpath(announcement_on_card_xpath_selector(course_title))
  end

  def subject_title_link(subject_title)
    fxpath(subject_link_selector(subject_title))
  end

  def subject_items_due(subject_title, due_today_text)
    fxpath(items_due_selector(subject_title, due_today_text))
  end

  def subject_items_missing(subject_title, number_items_missing)
    fxpath(items_missing_selector(subject_title, number_items_missing))
  end

  def today_header
    fj(today_selector)
  end

  def homeroom_course_title(title)
    fj(homeroom_course_title_selector(title))
  end

  def homeroom_course_title_link(title)
    fln(title)
  end

  def announcement_title(announcement_title)
    fj(announcement_title_selector(announcement_title))
  end

  def announcement_content_text(content_text)
    fj(announcement_content_text_selector(content_text))
  end

  def announcement_button
    fxpath(announcement_button_selector)
  end

  def announcement_edit_pencil
    f(announcement_edit_button_selector)
  end

  def staff_heading(staff_name)
    fj(staff_selector(staff_name))
  end

  def email_link(email_address)
    f(email_link_selector(email_address))
  end

  def instructor_role(role_type)
    fxpath(instructor_role_selector(role_type))
  end

  def instructor_bio(instructor_bio)
    fxpath(instructor_bio_selector(instructor_bio))
  end

  def subject_grades_title(title)
    fj(grade_title_selector(title))
  end

  def subject_grade(grade_value)
    fxpath(subject_grade_selector(grade_value))
  end

  def grade_progress_bar(grade_value)
    fxpath(grade_progress_bar_selector(grade_value))
  end

  def view_grades_button(course_id)
    f(view_grades_button_selector(course_id))
  end

  def grading_period_dropdown
    f(grading_period_dropdown_selector)
  end

  def beginning_of_week_date
    date_block = ff(week_date_selector)
    date_block[0].text == 'Today' ? date_block[1].text : date_block[0].text
  end

  def end_of_week_date
    ff(week_date_selector).last.text
  end

  def previous_week_button
    fxpath(previous_week_button_selector)
  end

  def next_week_button
    fxpath(next_week_button_selector)
  end

  def today_button
    fxpath(today_button_selector)
  end

  #----------------------- Actions & Methods -------------------------

  def check_enable_homeroom_checkbox
    enable_homeroom_checkbox.click
  end

  def select_homeroom_tab
    homeroom_tab.click
  end

  def select_schedule_tab
    schedule_tab.click
  end

  def select_grades_tab
    grades_tab.click
  end

  def select_resources_tab
    resources_tab.click
  end

  def retrieve_welcome_text
    welcome_title.text
  end

  def new_announcement(course, title, message)
    course.announcements.create!(title: title, message: message)
  end

  def navigate_to_subject(subject_title)
    subject_title_link(subject_title).click
  end

  def click_homeroom_course_title(course_title)
    homeroom_course_title_link(course_title).click
  end

  def click_announcement_button
    announcement_button.click
  end

  def announcement_button_exists?
    element_exists?(announcement_button_selector, true)
  end

  def click_announcement_edit_pencil
    announcement_edit_pencil.click
  end

  def click_previous_week_button
    previous_week_button.click
  end

  def click_next_week_button
    next_week_button.click
  end

  def click_today_button
    today_button.click
  end

  def beginning_weekday_calculation(current_date)
    (current_date.beginning_of_week(:sunday)).strftime("%B %-d")
  end

  def ending_weekday_calculation(current_date)
    (current_date.end_of_week(:sunday)).strftime("%B %-d")
  end
end
