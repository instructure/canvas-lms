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

describe "student dashboard Course grade widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

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

    it "displays last updated timestamp from course score" do
      # Get the enrollment and score and set it to 2 days ago
      enrollment = @student.enrollments.find_by(course: @course1)
      course_score = enrollment.find_score(course_score: true)
      course_score.update_columns(updated_at: 2.days.ago)

      go_to_dashboard

      # Check that last updated is displayed and capture initial value
      expect(course_last_updated(@course1.id)).to be_displayed
      initial_last_updated_text = course_last_updated(@course1.id).text

      # Update the score to trigger a new updated_at timestamp (now)
      course_score.update!(current_score: 90.0)
      refresh_page

      # Verify the timestamp has changed
      updated_last_updated_text = course_last_updated(@course1.id).text
      expect(updated_last_updated_text).not_to eq(initial_last_updated_text)
      expect(updated_last_updated_text).not_to be_empty
    end

    it "does not display last updated timestamp when grade is N/A" do
      course_with_student(user: @student, active_all: true, course_name: "No Grades Course")
      ungraded_course = @course

      go_to_dashboard

      expect(course_grade_text(ungraded_course.id).text).to eq("N/A")
      expect(element_exists?(course_last_updated_selector(ungraded_course.id))).to be_falsey
    end
  end

  context "Course grade widget pagination" do
    before :once do
      pagination_course_setup # Creates 20 additional courses
    end

    it "displays all pagination link on initial load" do
      go_to_dashboard

      expect(all_course_grade_items.size).to eq(6)
      expect(widget_pagination_button("Course grades", "1")).to be_displayed
      expect(widget_pagination_button("Course grades", "4")).to be_displayed
      widget_pagination_button("Course grades", "4").click
      expect(all_course_grade_items.size).to eq(4)
      widget_pagination_button("Course grades", "1").click
      expect(all_course_grade_items.size).to eq(6)
    end

    it "maintains pagination when switching all grades toggle" do
      go_to_dashboard

      expect(hide_all_grades_checkbox).to be_displayed
      force_click_native(hide_all_grades_checkbox_selector)
      expect(show_all_grades_checkbox).to be_displayed
      expect(widget_pagination_button("Course grades", "1")).to be_displayed
      expect(widget_pagination_button("Course grades", "4")).to be_displayed
      widget_pagination_button("Course grades", "4").click
      expect(show_all_grades_checkbox).to be_displayed
      widget_pagination_button("Course grades", "1").click
      expect(show_all_grades_checkbox).to be_displayed
    end
  end
end
