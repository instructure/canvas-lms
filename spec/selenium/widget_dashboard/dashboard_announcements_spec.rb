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

require_relative "page_objects/widget_dashboard_page"
require_relative "../helpers/student_dashboard_common"

describe "student dashboard announcements widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup # Creates 2 courses and a student enrolled in both
    dashboard_announcement_setup # Creates 5 Unread and 2 Read announcements
    set_widget_dashboard_flag(feature_status: true)
  end

  before do
    user_session(@student)
  end

  context "announcements widget smoke tests" do
    it "displays announcements in pagination" do
      go_to_dashboard

      expect(all_announcement_items.size).to eq(3)
      widget_pagination_button("Announcements", "2").click
      expect(all_announcement_items.size).to eq(2)

      filter_announcements_list_by("Read")
      expect(all_announcement_items.size).to eq(2)

      filter_announcements_list_by("All")
      expect(all_announcement_items.size).to eq(3)
      widget_pagination_button("Announcements", "2").click
      expect(all_announcement_items.size).to eq(3)
      widget_pagination_button("Announcements", "3").click
      expect(all_announcement_items.size).to eq(1)
    end

    it "can filter by read status" do
      go_to_dashboard

      expect(announcement_item(@announcement7.id)).to be_displayed
      expect(announcement_item(@announcement4.id)).to be_displayed
      expect(announcement_item(@announcement3.id)).to be_displayed

      filter_announcements_list_by("Read")
      wait_for_ajaximations
      expect(all_announcement_items.size).to eq(2)
      expect(announcement_item(@announcement6.id)).to be_displayed
      expect(announcement_item(@announcement5.id)).to be_displayed

      filter_announcements_list_by("All")
      wait_for_ajaximations
      expect(announcement_item(@announcement7.id)).to be_displayed
      expect(announcement_item(@announcement6.id)).to be_displayed
      expect(announcement_item(@announcement5.id)).to be_displayed
    end

    it "marks announcements as read" do
      go_to_dashboard

      expect(announcement_item_mark_read(@announcement7.id)).to be_displayed
      announcement_item_mark_read(@announcement7.id).click
      wait_for_ajaximations
      expect(element_exists?(announcement_item_selector(@announcement7.id))).to be_falsey

      filter_announcements_list_by("Read")
      wait_for_ajaximations
      expect(announcement_item_mark_unread(@announcement7.id)).to be_displayed
    end

    it "marks announcements as unread" do
      go_to_dashboard

      filter_announcements_list_by("Read")
      wait_for_ajaximations
      expect(announcement_item_mark_unread(@announcement6.id)).to be_displayed
      announcement_item_mark_unread(@announcement6.id).click
      wait_for_ajaximations
      expect(element_exists?(announcement_item_selector(@announcement6.id))).to be_falsey

      filter_announcements_list_by("Unread")
      expect(announcement_item_mark_read(@announcement6.id)).to be_displayed
    end

    it "navigates to the announcement page when clicking announcement title" do
      go_to_dashboard

      expect(announcement_item_title(@announcement7.id)).to be_displayed
      announcement_item_title(@announcement7.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/discussion_topics/#{@announcement7.id}")
    end
  end

  context "section specific announcements" do
    before :once do
      @section1 = @course1.default_section
      @section2 = @course1.course_sections.create!(name: "test section 2")
      student_in_section(@section2, user: @student)

      @announcement8 = @course1.announcements.create!(title: "section 1 : announcement",
                                                      message: "here is the announcement message for section 1",
                                                      is_section_specific: true,
                                                      course_sections: [@section1])

      @announcement9 = @course1.announcements.create!(title: "section 2 : announcement",
                                                      message: "here is the announcement message for section 2",
                                                      is_section_specific: true,
                                                      course_sections: [@section2])
    end

    it "displays section specific announcements" do
      go_to_dashboard
      expect(announcement_item(@announcement9.id)).to be_displayed
      expect(element_exists?(announcement_item_selector(@announcement8.id))).to be_falsey
    end
  end

  context "announcements widget pagination" do
    before :once do
      pagination_announcement_setup # Creates 15 read and 11 unread announcements
    end

    it "displays all pagination link on initial load" do
      go_to_dashboard
      expect(widget_pagination_button("Announcements", "1")).to be_displayed
      expect(widget_pagination_button("Announcements", "6")).to be_displayed
      widget_pagination_button("Announcements", "6").click
      widget_pagination_button("Announcements", "1").click
      expect(widget_pagination_button("Announcements", "6")).to be_displayed

      filter_announcements_list_by("All")
      expect(widget_pagination_button("Announcements", "1")).to be_displayed
      expect(widget_pagination_button("Announcements", "11")).to be_displayed
      widget_pagination_button("Announcements", "11").click
      widget_pagination_button("Announcements", "1").click
      expect(widget_pagination_button("Announcements", "11")).to be_displayed

      filter_announcements_list_by("Read")
      expect(widget_pagination_button("Announcements", "1")).to be_displayed
      expect(widget_pagination_button("Announcements", "6")).to be_displayed
      widget_pagination_button("Announcements", "6").click
      widget_pagination_button("Announcements", "1").click
      expect(widget_pagination_button("Announcements", "6")).to be_displayed
    end

    it "maintains pagination when switching filters" do
      go_to_dashboard
      expect(widget_pagination_button("Announcements", "6")).to be_displayed
      filter_announcements_list_by("All")
      expect(widget_pagination_button("Announcements", "11")).to be_displayed
      filter_announcements_list_by("Read")
      expect(widget_pagination_button("Announcements", "6")).to be_displayed
      filter_announcements_list_by("All")
      expect(widget_pagination_button("Announcements", "11")).to be_displayed
      filter_announcements_list_by("Unread")
      expect(widget_pagination_button("Announcements", "6")).to be_displayed
    end

    it "navigates using prev and next button" do
      go_to_dashboard

      expect(widget_pagination_button("Announcements", "6")).to be_displayed
      expect(element_exists?(widget_pagination_prev_button_selector("Announcements"))).to be_falsey
      widget_pagination_next_button("Announcements").click
      expect(widget_pagination_prev_button("Announcements")).to be_displayed
      widget_pagination_next_button("Announcements").click
      expect(widget_pagination_button("Announcements", "4")).to be_displayed
      widget_pagination_next_button("Announcements").click
      expect(widget_pagination_button("Announcements", "5")).to be_displayed
      widget_pagination_next_button("Announcements").click
      expect(widget_pagination_prev_button("Announcements")).to be_displayed
      widget_pagination_next_button("Announcements").click
      expect(element_exists?(widget_pagination_next_button_selector("Announcements"))).to be_falsey

      widget_pagination_prev_button("Announcements").click
      expect(widget_pagination_next_button("Announcements")).to be_displayed
      widget_pagination_prev_button("Announcements").click
      expect(widget_pagination_button("Announcements", "4")).to be_displayed
      widget_pagination_prev_button("Announcements").click
      expect(widget_pagination_button("Announcements", "3")).to be_displayed
      widget_pagination_prev_button("Announcements").click
      expect(widget_pagination_next_button("Announcements")).to be_displayed
      widget_pagination_prev_button("Announcements").click
      expect(element_exists?(widget_pagination_prev_button_selector("Announcements"))).to be_falsey
    end
  end
end
