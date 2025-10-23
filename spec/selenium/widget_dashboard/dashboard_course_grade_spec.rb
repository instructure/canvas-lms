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

describe "student dashboard Course grade widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage

  before :once do
    dashboard_student_setup # Creates 2 courses and a student enrolled in both
    dashboard_course_assignment_setup # Add 11 assignments
    dashboard_course_submission_setup
    dashboard_course_grade_setup
    set_widget_dashboard_flag(feature_status: true)
  end

  before do
    user_session(@student)
  end

  context "course grade widget smoke tests" do
    it "undisplay and display individual grades with toggle" do
      go_to_dashboard

      expect(hide_single_grade_button(@course1.id)).to be_displayed
      expect(course_grade_text(@course1.id)).to be_displayed
      expect(course_grade_text(@course2.id)).to be_displayed
      hide_single_grade_button(@course1.id).click
      expect(show_single_grade_button(@course1.id)).to be_displayed
      expect(element_exists?(course_grade_text_selector(@course1.id))).to be_falsey
      expect(course_grade_text(@course2.id)).to be_displayed

      show_single_grade_button(@course1.id).click
      expect(hide_single_grade_button(@course1.id)).to be_displayed
      expect(course_grade_text(@course1.id)).to be_displayed
      expect(course_grade_text(@course2.id)).to be_displayed
    end

    it "undisplay and display all grades with toggle" do
      go_to_dashboard

      expect(hide_all_grades_checkbox).to be_displayed
      expect(course_grade_text(@course1.id)).to be_displayed
      expect(course_grade_text(@course2.id)).to be_displayed
      force_click_native(hide_all_grades_checkbox_selector)
      expect(show_all_grades_checkbox).to be_displayed
      expect(element_exists?(course_grade_text_selector(@course1.id))).to be_falsey
      expect(element_exists?(course_grade_text_selector(@course2.id))).to be_falsey

      force_click_native(show_all_grades_checkbox_selector)
      expect(hide_all_grades_checkbox).to be_displayed
      expect(course_grade_text(@course1.id)).to be_displayed
      expect(course_grade_text(@course2.id)).to be_displayed
    end

    it "navigates to the course gradebook when clicking view gradebook link" do
      go_to_dashboard

      expect(course_gradebook_link(@course1.id)).to be_displayed
      course_gradebook_link(@course1.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/grades")
    end

    it "displays course grades in pagination" do
      @course3 = course_factory(active_all: true, course_name: "Course 3")
      @course4 = course_factory(active_all: true, course_name: "Course 4")
      @course5 = course_factory(active_all: true, course_name: "Course 5")
      @course6 = course_factory(active_all: true, course_name: "Course 6")
      @course7 = course_factory(active_all: true, course_name: "Course 7")

      @course3.enroll_student(@student, enrollment_state: :active)
      @course4.enroll_student(@student, enrollment_state: :active)
      @course5.enroll_student(@student, enrollment_state: :active)
      @course6.enroll_student(@student, enrollment_state: :active)
      @course7.enroll_student(@student, enrollment_state: :active)

      go_to_dashboard

      expect(all_course_grade_items.size).to eq(6)
      expect(course_grade_text(@course3.id).text).to eq("N/A")
      widget_pagination_button("course-grades", "2").click
      expect(all_course_grade_items.size).to eq(1)
    end
  end
end
