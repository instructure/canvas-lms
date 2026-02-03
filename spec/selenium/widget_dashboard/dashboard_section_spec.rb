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

describe "student dashboard section specific tests", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    multi_section_course_setup # Creates a instructor in 3 sections and a student in one section
    section_specific_announcements_setup # Creates 7 section specific announcements
    section_specific_assignments_setup # Creates 7 section specific assignments
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@multi_stu_sec1, @multi_stu_sec2)
  end

  context "as student" do
    before do
      user_session(@multi_stu_sec1)
    end

    it "displays instructor once when instructor enrolled in multiple sections" do
      go_to_dashboard

      expect(instructor_list_item(@shared_teacher.name)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
    end

    it "displays instructor once when student enrolled in multiple sections" do
      @multi_course.enroll_student(@multi_stu_sec1, section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)

      go_to_dashboard

      expect(instructor_list_item(@shared_teacher.name)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
    end

    it "displays section specific announcements when student enrolled in multi sections" do
      go_to_dashboard

      expect(announcement_item(@section1_2_3_ann6.id)).to be_displayed
      expect(announcement_item(@section2_3_ann5.id)).to be_displayed
      expect(announcement_item(@section1_2_ann4.id)).to be_displayed
      widget_pagination_button("Announcements", "2").click
      expect(announcement_item(@section3_ann3.id)).to be_displayed
      expect(announcement_item(@section1_ann1.id)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
      expect(element_exists?(announcement_item_selector(@section2_ann2.id))).to be_falsey
      expect(element_exists?(announcement_item_selector(@section2_4_ann7.id))).to be_falsey
    end

    it "displays section specific assignments when student enrolled in multi sections" do
      go_to_dashboard

      expect(course_work_item(@section1_hw1.id)).to be_displayed
      expect(element_exists?(course_work_item_selector(@section2_hw2.id))).to be_falsey
      expect(course_work_item(@section3_hw3.id)).to be_displayed
      expect(course_work_item(@section1_2_hw4.id)).to be_displayed
      expect(course_work_item(@section2_3_hw5.id)).to be_displayed
      expect(course_work_item(@section1_2_3_hw6.id)).to be_displayed
      expect(element_exists?(course_work_item_selector(@section2_4_hw7.id))).to be_falsey
      expect(all_course_work_items.size).to eq(5)
    end
  end

  context "as observer" do
    before :once do
      observer_w_section_specific_course_setup
      enable_widget_dashboard_for(@multi_section_observer)
    end

    before do
      user_session(@multi_section_observer)
    end

    it "displays instructor once when instructor enrolled in multiple sections" do
      go_to_dashboard

      select_observed_student(@multi_stu_sec1.name)
      expect(instructor_list_item(@shared_teacher.name)).to be_displayed
      expect(all_message_buttons.size).to eq(2)

      select_observed_student(@multi_stu_sec2.name)
      expect(instructor_list_item(@shared_teacher.name)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
    end

    it "displays instructor once when student enrolled in multiple sections" do
      @multi_course.enroll_student(@multi_stu_sec1, section: @section3, enrollment_state: "active", allow_multiple_enrollments: true)
      @multi_course.enroll_student(@multi_stu_sec2, section: @section4, enrollment_state: "active", allow_multiple_enrollments: true)

      go_to_dashboard
      select_observed_student(@multi_stu_sec1.name)
      expect(instructor_list_item(@shared_teacher.name)).to be_displayed
      expect(all_message_buttons.size).to eq(2)

      select_observed_student(@multi_stu_sec2.name)
      expect(instructor_list_item(@shared_teacher.name)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
    end

    it "displays section specific announcements when student enrolled in multi sections" do
      go_to_dashboard

      select_observed_student(@multi_stu_sec1.name)
      expect(announcement_item(@section1_2_3_ann6.id)).to be_displayed
      expect(announcement_item(@section2_3_ann5.id)).to be_displayed
      expect(announcement_item(@section1_2_ann4.id)).to be_displayed
      widget_pagination_button("Announcements", "2").click
      expect(announcement_item(@section3_ann3.id)).to be_displayed
      expect(announcement_item(@section1_ann1.id)).to be_displayed
      expect(all_message_buttons.size).to eq(2)
      expect(element_exists?(announcement_item_selector(@section2_ann2.id))).to be_falsey
      expect(element_exists?(announcement_item_selector(@section2_4_ann7.id))).to be_falsey

      select_observed_student(@multi_stu_sec2.name)
      expect(announcement_item(@section2_4_ann7.id)).to be_displayed
      expect(announcement_item(@section1_2_3_ann6.id)).to be_displayed
      expect(announcement_item(@section2_3_ann5.id)).to be_displayed
      widget_pagination_button("Announcements", "2").click
      expect(announcement_item(@section1_2_ann4.id)).to be_displayed
      expect(element_exists?(announcement_item_selector(@section3_ann3.id))).to be_falsey
      expect(announcement_item(@section2_ann2.id)).to be_displayed
      expect(element_exists?(announcement_item_selector(@section1_ann1.id))).to be_falsey
      expect(all_message_buttons.size).to eq(2)
    end

    it "displays section specific assignments when student enrolled in multi sections" do
      go_to_dashboard

      select_observed_student(@multi_stu_sec1.name)
      expect(course_work_item(@section1_hw1.id)).to be_displayed
      expect(element_exists?(course_work_item_selector(@section2_hw2.id))).to be_falsey
      expect(course_work_item(@section3_hw3.id)).to be_displayed
      expect(course_work_item(@section1_2_hw4.id)).to be_displayed
      expect(course_work_item(@section2_3_hw5.id)).to be_displayed
      expect(course_work_item(@section1_2_3_hw6.id)).to be_displayed
      expect(element_exists?(course_work_item_selector(@section2_4_hw7.id))).to be_falsey
      expect(all_course_work_items.size).to eq(5)

      select_observed_student(@multi_stu_sec2.name)
      expect(element_exists?(course_work_item_selector(@section1_hw1.id))).to be_falsey
      expect(course_work_item(@section2_hw2.id)).to be_displayed
      expect(element_exists?(course_work_item_selector(@section3_hw3.id))).to be_falsey
      expect(course_work_item(@section1_2_hw4.id)).to be_displayed
      expect(course_work_item(@section2_3_hw5.id)).to be_displayed
      expect(course_work_item(@section1_2_3_hw6.id)).to be_displayed
      expect(course_work_item(@section2_4_hw7.id)).to be_displayed
      expect(all_course_work_items.size).to eq(5)
    end
  end
end
