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
require_relative "page_objects/course_tab_page"
require_relative "../helpers/student_dashboard_common"

describe "student dashboard", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include CourseTabPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup
    dashboard_pending_enrollment_setup
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student)
  end

  before do
    user_session(@student)
  end

  context "Pending enrollment scenarios" do
    before do
      @enrollment = @course3.enroll_student(@student, enrollment_state: "invited")
    end

    it "removes invitation from page after accepting", priority: "1" do
      get "/"

      expect(enrollment_invitation).to be_displayed
      expect(enrollment_invitation_accept_button).to be_displayed

      wait_for_new_page_load { enrollment_invitation_accept_button.click }

      expect(element_exists?(enrollment_invitation_selector)).to be_falsey
    end

    it "removes invitation from page after declining", priority: "1" do
      get "/"

      expect(enrollment_invitation).to be_displayed
      expect(enrollment_invitation_decline_button).to be_displayed

      enrollment_invitation_decline_button.click
      wait_for_ajaximations

      expect(element_exists?(enrollment_invitation_selector)).to be_falsey
    end

    it "does not display dashboard content for pending enrollments" do
      go_to_dashboard
      expect(enrollment_invitation).to be_displayed

      expect(course_work_summary_stats("Due").text).to eq("0\nDue")
      expect(course_work_summary_stats("Missing").text).to eq("0\nMissing")
      expect(course_work_summary_stats("Submitted").text).to eq("0\nSubmitted")

      expect(element_exists?(hide_single_grade_button_selector(@course3.id))).to be_falsey

      expect(no_announcements_message).to be_displayed

      expect(all_message_buttons.size).to eq(4)
      expect(element_exists?(message_instructor_button_selector(@teacher1.id))).to be_truthy
    end
  end

  context "multiple enrollment invitations" do
    before :once do
      @course4 = course_factory(active_all: true, course_name: "Test Course 4")
      @enrollment1 = @course3.enroll_student(@student, enrollment_state: "invited")
      @enrollment2 = @course4.enroll_student(@student, enrollment_state: "invited")
    end

    it "removes only the accepted invitation", priority: "1" do
      get "/"
      expect(all_enrollment_invitations.length).to eq(2)

      wait_for_new_page_load do
        all_enrollment_invitations.first.find_element(css: "button", text: "Accept").click
      end

      expect(all_enrollment_invitations.length).to eq(1)
    end
  end

  context "Past or inactive course filtering" do
    before :once do
      dashboard_inactive_courses_setup # enrolls @student_w_inactive in only inactive or concluded courses
      enable_widget_dashboard_for(@student_w_inactive)
    end

    it "displays only active courses" do
      user_session(@student_w_inactive)

      go_to_dashboard
      expect(element_exists?(enrollment_invitation_selector)).to be_falsey
      expect(no_announcements_message).to be_displayed
      expect(no_instructors_message).to be_displayed

      go_to_course_tab
      expect(no_enrolled_courses_message).to be_displayed
    end

    it "displays only active courses for observed courses and students" do
      observer_w_inactive_courses_setup # enrolls in inactive courses and @course1
      enable_widget_dashboard_for(@observer)
      user_session(@observer)
      go_to_dashboard

      select_observed_student(@student_w_inactive.name)
      expect(message_instructor_button(@teacher1.id)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
    end
  end

  context "new widgets on zero states" do
    it "shows empty state when no graded submissions exist" do
      add_widget_to_dashboard(@student, :recent_grades, 1)
      go_to_dashboard

      expect(recent_grades_empty_message).to be_displayed
      expect(recent_grades_empty_message.text).to include("No recent grades available")
    end

    it "shows empty state message when no messages exist" do
      add_widget_to_dashboard(@student, :inbox, 1)
      go_to_dashboard

      expect(inbox_no_messages_message).to be_displayed
      expect(inbox_show_all_messages_link).to be_displayed
    end

    it "shows empty state for unread filter when only read messages exist" do
      # Create student with only read messages
      create_multiple_conversations(@student, @teacher2, 3, "read")
      add_widget_to_dashboard(@student, :inbox, 1)
      go_to_dashboard

      expect(inbox_no_messages_message).to be_displayed
      filter_inbox_messages_by("All")
      expect(all_inbox_message_items.size).to eq(3)
    end
  end
end
