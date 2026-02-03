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

describe "student dashboard people widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup # Creates 2 courses and a student enrolled in both
    dashboard_people_setup # Add one more teacher and TA to course 1
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student)
  end

  before do
    user_session(@student)
  end

  context "people widget smoke tests" do
    it "displays teachers and TA" do
      go_to_dashboard

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(message_instructor_button(@teacher2.id)).to be_displayed
      expect(message_instructor_button(@ta1.id)).to be_displayed
    end

    it "can message instructors" do
      go_to_dashboard

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      message_instructor_button(@teacher1.id).click
      wait_for_ajaximations
      expect(send_message_to_modal(@teacher1.name)).to be_displayed
      expect(message_modal_subject_input).to be_displayed
      message_modal_subject_input.send_keys("hello teacher")
      expect(message_modal_body_textarea).to be_displayed
      message_modal_body_textarea.send_keys("just wanted to say hi")
      message_modal_send_button.click
      expect(message_modal_alert).to be_displayed
      expect(message_modal_alert.text).to include("Your message was sent!")
    end
  end

  context "People widget pagination" do
    before :once do
      pagination_course_setup # Creates 20 courses with different teachers
    end

    it "displays all pagination link on initial load" do
      go_to_dashboard

      expect(all_message_buttons.size).to eq(5)
      expect(widget_pagination_button("Instructors", "1")).to be_displayed
      expect(widget_pagination_button("Instructors", "2")).to be_displayed
      expect(widget_pagination_button("Instructors", "10")).to be_displayed
      widget_pagination_button("Instructors", "10").click
      expect(all_message_buttons.size).to eq(1)
      widget_pagination_button("Instructors", "1").click
      expect(all_message_buttons.size).to eq(5)
    end

    it "navigates using prev and next button" do
      go_to_dashboard

      expect(widget_pagination_button("Instructors", "10")).to be_displayed
      expect(element_exists?(widget_pagination_prev_button_selector("Instructors"))).to be_falsey
      widget_pagination_next_button("Instructors").click
      expect(widget_pagination_prev_button("Instructors")).to be_displayed
      widget_pagination_next_button("Instructors").click
      expect(widget_pagination_button("Instructors", "4")).to be_displayed
      widget_pagination_next_button("Instructors").click
      widget_pagination_button("Instructors", "10").click
      expect(element_exists?(widget_pagination_next_button_selector("Instructors"))).to be_falsey

      widget_pagination_prev_button("Instructors").click
      expect(widget_pagination_next_button("Instructors")).to be_displayed
      widget_pagination_prev_button("Instructors").click
      expect(widget_pagination_button("Instructors", "7")).to be_displayed
      widget_pagination_prev_button("Instructors").click
      expect(widget_pagination_button("Instructors", "6")).to be_displayed
      widget_pagination_button("Instructors", "1").click
      expect(element_exists?(widget_pagination_prev_button_selector("Instructors"))).to be_falsey
    end
  end

  context "People widget filters" do
    it "displays course and role filters" do
      go_to_dashboard

      expect(course_filter_select).to be_displayed
      expect(role_filter_select).to be_displayed
    end

    it "filters instructors by role" do
      go_to_dashboard

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(message_instructor_button(@ta1.id)).to be_displayed

      filter_people_by(:role, "Teacher")

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(element_exists?(message_instructor_button_selector(@ta1.id))).to be_falsey
    end

    it "filters instructors by course" do
      go_to_dashboard

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(message_instructor_button(@teacher2.id)).to be_displayed

      filter_people_by(:course, @course1.name)

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(message_instructor_button(@ta1.id)).to be_displayed
      expect(element_exists?(message_instructor_button_selector(@teacher2.id))).to be_falsey
    end

    it "persists filter selections across page loads" do
      go_to_dashboard

      filter_people_by(:role, "Teacher")

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(element_exists?(message_instructor_button_selector(@ta1.id))).to be_falsey

      refresh_page
      wait_for_ajaximations

      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(element_exists?(message_instructor_button_selector(@ta1.id))).to be_falsey
    end
  end
end
