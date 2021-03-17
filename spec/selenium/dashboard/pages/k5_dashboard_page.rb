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
end
