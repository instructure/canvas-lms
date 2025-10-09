# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module WidgetDashboardPage
  #------------------------------ Selectors -----------------------------
  def announcement_filter_select
    "[data-testid='announcement-filter-select']"
  end

  def announcement_item_selector(item_id)
    "[data-testid='announcement-item-#{item_id}']"
  end

  def announcement_item_title_selector(item_id)
    "[data-testid='announcement-item-#{item_id}'] a[href]"
  end

  def announcement_item_mark_read_selector(item_id)
    "[data-testid='mark-read-#{item_id}']"
  end

  def announcement_item_mark_unread_selector(item_id)
    "[data-testid='mark-unread-#{item_id}']"
  end

  def announcement_item_link_selector(item_id)
    "[data-testid='read-more-#{item_id}']"
  end

  def widget_pagination_button_selector(widget, page_number)
    "[data-testid='widget-#{widget}-widget'] [data-testid='pagination-container'] button:contains('#{page_number}')"
  end

  def people_widget_selector
    "[data-testid='widget-people-widget']"
  end

  def message_instructor_button_selector(account_id, course_id)
    "[data-testid='message-button-#{account_id}-#{course_id}']"
  end

  def send_message_to_modal_selector(teacher_name)
    "span[role = 'dialog'][aria-label='Send Message to #{teacher_name}']"
  end

  def message_modal_subject_input_selector
    "span[role = 'dialog'] input[type='text']"
  end

  def message_modal_body_textarea_selector
    "span[role = 'dialog'] textarea"
  end

  def message_modal_send_button_selector
    "button[data-testid='message-students-submit']"
  end

  def message_modal_alert_selector
    ".MessageStudents__Alert"
  end

  #------------------------------ Elements ------------------------------

  def announcement_filter
    f(announcement_filter_select)
  end

  def all_announcement_items
    ff("[data-testid*='announcement-item-']")
  end

  def announcement_item(item_id)
    f(announcement_item_selector(item_id))
  end

  def announcement_item_title(item_id)
    f(announcement_item_title_selector(item_id))
  end

  def announcement_item_mark_read(item_id)
    f(announcement_item_mark_read_selector(item_id))
  end

  def announcement_item_mark_unread(item_id)
    f(announcement_item_mark_unread_selector(item_id))
  end

  def announcement_item_link(item_id)
    f(announcement_item_link_selector(item_id))
  end

  def widget_pagination_button(widget, page_number)
    fj(widget_pagination_button_selector(widget, page_number))
  end

  def people_widget
    f(people_widget_selector)
  end

  def all_message_buttons
    ff("[data-testid*='message-button-']")
  end

  def message_instructor_button(account_id, course_id)
    f(message_instructor_button_selector(account_id, course_id))
  end

  def send_message_to_modal(teacher_name)
    f(send_message_to_modal_selector(teacher_name))
  end

  def message_modal_subject_input
    f(message_modal_subject_input_selector)
  end

  def message_modal_body_textarea
    f(message_modal_body_textarea_selector)
  end

  def message_modal_send_button
    f(message_modal_send_button_selector)
  end

  def message_modal_alert
    f(message_modal_alert_selector)
  end

  #------------------------------ Actions -------------------------------

  def dashboard_student_setup
    @course1 = course_factory(active_all: true, course_name: "Course 1")
    @course2 = course_factory(active_all: true, course_name: "Course 2")

    @teacher1 = user_factory(active_all: true, name: "Nancy Smith")
    @teacher2 = user_factory(active_all: true, name: "John Doe")
    @student = user_factory(active_all: true, name: "Jane Brown")

    @course1.enroll_teacher(@teacher1, enrollment_state: :active)
    @course2.enroll_teacher(@teacher2, enrollment_state: :active)
    @course1.enroll_student(@student, enrollment_state: :active)
    @course2.enroll_student(@student, enrollment_state: :active)
  end

  def set_widget_dashboard_flag(feature_status: true)
    feature_status ? @course1.root_account.enable_feature!(:widget_dashboard) : @course1.root_account.disable_feature!(:widget_dashboard)
  end

  def dashboard_announcement_setup
    @announcement1 = @course1.announcements.create!(title: "Course 1 - Announcement title 1", message: "Announcement message 1")
    @announcement2 = @course2.announcements.create!(title: "Course 2 - Announcement title 2", message: "Announcement message 2")
    @announcement3 = @course1.announcements.create!(title: "Course 1 - Announcement title 3", message: "Announcement message 3")
    @announcement4 = @course2.announcements.create!(title: "Course 2 - Announcement title 4", message: "Announcement message 4")
    @announcement5 = @course1.announcements.create!(title: "Course 1 - Announcement title 5", message: "Announcement message 5")
    @announcement6 = @course2.announcements.create!(title: "Course 2 - Announcement title 6", message: "Announcement message 6")
    @announcement7 = @course1.announcements.create!(title: "Course 1 - Announcement title 7", message: "Announcement message 7. This is a longer message to test the read more link functionality on the announcements widget. This message should be long enough to be truncated.")

    @announcement6.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
    @announcement5.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
  end

  def dashboard_people_setup
    @ta1 = course_with_ta(name: "Alice Davis", course: @course1, active_all: true).user
    @ta2 = course_with_ta(name: "Bob Johnson", course: @course2, active_all: true).user
  end

  def filter_announcements_list_by(status)
    announcement_filter.click
    click_INSTUI_Select_option(announcement_filter_select, status)
  end

  def go_to_announcement_widget
    get "/"
    wait_for_ajaximations
    expect(announcement_filter).to be_displayed
  end

  def go_to_people_widget
    get "/"
    wait_for_ajaximations
    expect(people_widget).to be_displayed
  end
end
