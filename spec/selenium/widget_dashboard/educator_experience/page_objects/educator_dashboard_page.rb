# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../../../common"

module EducatorDashboardPage
  #------------------------------ Selectors -----------------------------

  def widget_container_selector(widget_id)
    "[data-testid='widget-container-#{widget_id}-widget']"
  end

  # Announcement creation selectors
  def create_announcement_button_selector
    "[data-testid='create-announcement-button']"
  end

  def announcement_creation_modal_selector
    "[role='dialog'][aria-label='Create announcement']"
  end

  def announcement_title_input_selector
    "[data-testid='announcement-title-input']"
  end

  def announcement_content_input_selector
    "[data-testid='announcement-content-input']"
  end

  def announcement_course_select_selector
    "[data-testid='announcement-course-select']"
  end

  def announcement_send_button_selector
    "[data-testid='announcement-send-button']"
  end

  def announcement_course_tag_selector(course_id)
    "[data-testid='course-tag-#{course_id}']"
  end

  def rce_announcement_textarea_selector
    "#{announcement_creation_modal_selector} textarea[id^='announcement-editor-']"
  end

  def rce_announcement_iframe_selector
    "#{announcement_creation_modal_selector} .tox-edit-area__iframe"
  end

  #------------------------------ Elements ------------------------------

  def widget_container(widget_id)
    f(widget_container_selector(widget_id))
  end

  # Announcement creation elements
  def create_announcement_button
    f(create_announcement_button_selector)
  end

  def announcement_title_input
    f(announcement_title_input_selector)
  end

  def announcement_content_input
    f(announcement_content_input_selector)
  end

  def announcement_send_button
    f(announcement_send_button_selector)
  end

  def rce_announcement_iframe
    f(rce_announcement_iframe_selector)
  end
  #------------------------------ Actions -------------------------------

  def go_to_dashboard
    get "/"
    wait_for_ajaximations
  end

  def open_announcement_modal
    go_to_dashboard
    expect(widget_container("educator-announcement-creation")).to be_displayed
    create_announcement_button.click
    wait_for_ajaximations
    expect(f(announcement_creation_modal_selector)).to be_displayed
  end

  def fill_announcement_form(title:, content:)
    announcement_title_input.send_keys(title)
    type_in_tiny(rce_announcement_textarea_selector, content)
  end

  def select_course_in_modal(course_name)
    click_INSTUI_Select_option(announcement_course_select_selector, course_name)
    wait_for_ajaximations
  end

  def click_announcement_send_button
    announcement_send_button.click
    wait_for_ajaximations
  end

  def announcement_modal_open?
    element_exists?(announcement_creation_modal_selector)
  end

  def announcement_course_tag_exists?(course_id)
    element_exists?(announcement_course_tag_selector(course_id))
  end
end
