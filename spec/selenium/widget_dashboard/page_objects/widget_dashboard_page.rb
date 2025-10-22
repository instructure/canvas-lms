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

  def pagination_button_selector(page_number)
    "[data-testid='pagination-container'] button:contains('#{page_number}')"
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

  def pagination_button(page_number)
    fj(pagination_button_selector(page_number))
  end

  #------------------------------ Actions -------------------------------

  def dashboard_student_setup
    @course1 = course_factory(active_all: true, course_name: "Course 1")
    @course2 = course_factory(active_all: true, course_name: "Course 2")

    @teacher1 = user_factory(active_all: true, name: "Teacher 1")
    @teacher2 = user_factory(active_all: true, name: "Teacher 2")
    @student = user_factory(active_all: true, name: "Student")

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

  def filter_announcements_list_by(status)
    announcement_filter.click
    click_INSTUI_Select_option(announcement_filter_select, status)
  end

  def go_to_announcement_widget
    get "/"
    wait_for_ajaximations
    expect(announcement_filter).to be_displayed
  end
end
