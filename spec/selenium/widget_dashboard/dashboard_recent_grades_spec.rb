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

describe "student dashboard Recent grades & feedback widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup
    dashboard_course_assignment_setup
    dashboard_course_submission_setup
    dashboard_course_grade_setup
    dashboard_recent_grades_setup
    set_widget_dashboard_flag(feature_status: true)
  end

  before do
    user_session(@student)
  end

  context "recent grades & feedback widget smoke tests" do
    it "displays assignment, discussion, and quiz submissions" do
      go_to_dashboard

      expect(all_recent_grade_course_name.size).to eq(5)
      expect(recent_grades_widget.text).to include(@graded_assignment.name)
      expect(recent_grades_widget.text).to include(@graded_discussion.title)
      expect(recent_grades_widget.text).to include(@graded_quiz.title)
      expect(recent_grades_widget.text).to include(@submitted_assignment.name)
      expect(recent_grades_widget.text).to include(@submitted_discussion.title)
    end

    it "can filter items in course" do
      go_to_dashboard
      filter_recent_grades_by_course(@course1.name)
      expect(recent_grades_widget.text).to include(@submitted_assignment.name)
      expect(recent_grades_widget.text).to include(@graded_discussion.title)
      expect(recent_grades_widget.text).to include(@graded_quiz.title)
      expect(all_recent_grade_course_name.size).to eq(3)

      filter_recent_grades_by_course(@course2.name)
      expect(recent_grades_widget.text).to include(@graded_assignment.name)
      expect(recent_grades_widget.text).to include(@submitted_discussion.title)
      expect(all_recent_grade_course_name.size).to eq(2)
    end
  end

  context "Recent grades & feedback widget pagination" do
    before :once do
      pagination_recent_grades_setup # Creates 27 assignments
    end

    it "displays all pagination link on initial load" do
      go_to_dashboard

      expect(all_recent_grade_course_name.size).to eq(5)
      expect(widget_pagination_button("Recent grades", "1")).to be_displayed
      expect(widget_pagination_button("Recent grades", "7")).to be_displayed
      widget_pagination_button("Recent grades", "7").click
      expect(all_recent_grade_course_name.size).to eq(2)
      expect(widget_pagination_button("Recent grades", "1")).to be_displayed
    end

    it "maintains pagination when switching filters" do
      go_to_dashboard

      expect(widget_pagination_button("Recent grades", "7")).to be_displayed
      filter_recent_grades_by_course(@course1.name)
      expect(widget_pagination_button("Recent grades", "5")).to be_displayed
      widget_pagination_button("Recent grades", "5").click
      expect(all_recent_grade_course_name.size).to eq(1)

      filter_recent_grades_by_course(@course2.name)
      expect(widget_pagination_button("Recent grades", "3")).to be_displayed
      widget_pagination_button("Recent grades", "3").click
      expect(all_recent_grade_course_name.size).to eq(1)
    end
  end

  context "navigation workflows" do
    it "navigates to grades page when clicking view all grades link" do
      go_to_dashboard

      expect(recent_grades_view_all_link).to be_displayed
      recent_grades_view_all_link.click
      expect(driver.current_url).to include("/grades")
    end

    it "navigates to assignment page when clicking open assignment link" do
      submission = @graded_assignment.submission_for_student(@student)

      go_to_dashboard
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_open_assignment_link(submission.id)).to be_displayed
      recent_grade_open_assignment_link(submission.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/assignments/#{@graded_assignment.id}")
    end

    it "navigates to course grades page when clicking what-if grading tool link" do
      submission = @graded_quiz.assignment.submission_for_student(@student)

      go_to_dashboard
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_whatif_link(submission.id)).to be_displayed
      recent_grade_whatif_link(submission.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/grades")
    end

    it "navigates to conversations with compose modal when clicking message instructor" do
      submission = @graded_discussion.submission_for_student(@student)

      go_to_dashboard
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_message_instructor_link(submission.id)).to be_displayed
      recent_grade_message_instructor_link(submission.id).click

      expect(driver.current_url).to include("/conversations")
      # Verifying pre-filled with the correct course context
      expect(driver.current_url).to include("context_id=course_#{@course1.id}")
      # Verifying opened the compose modal
      expect(driver.current_url).to include("compose=true")
    end

    it "navigates to assignment with feedback when clicking view inline feedback link" do
      submission = @graded_assignment.submission_for_student(@student)

      go_to_dashboard
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_view_feedback_link(submission.id)).to be_displayed
      expect(recent_grade_feedback_section(submission.id).text).to include("Place for improvement...")
      recent_grade_view_feedback_link(submission.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/assignments/#{@graded_assignment.id}")
    end
  end
end
