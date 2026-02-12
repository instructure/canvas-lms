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

require_relative "page_objects/widget_dashboard_page"
require_relative "../helpers/student_dashboard_common"

describe "student dashboard todo widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup # Creates 2 courses and a student enrolled in both
    dashboard_course_assignment_setup # Creates assignments, quiz, discussion with various due dates
    dashboard_course_submission_setup
    dashboard_course_grade_setup
    dashboard_announcement_setup # Creates announcements
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student)
    add_widget_to_dashboard(@student, :todo_list, 1) # Add todo widget to dashboard

    @incomplete_quiz = Quizzes::Quiz.find_by(assignment_id: @missing_quiz.id)
    @incomplete_discussion = DiscussionTopic.find_by(assignment_id: @missing_graded_discussion.id)
    @completed_discussion1 = DiscussionTopic.find_by(assignment_id: @graded_discussion.id)
    @completed_discussion2 = DiscussionTopic.find_by(assignment_id: @submitted_discussion.id)
  end

  before do
    user_session(@student)
  end

  context "todo widget smoke tests" do
    it "displays assigned assignments" do
      go_to_dashboard

      expect(todo_item(@incomplete_quiz.id).text).to include("Quiz\nCourse 2: missing_quiz\nCourse 2")
      expect(todo_item(@incomplete_quiz.id).text).to include("Overdue")

      expect(todo_item(@missing_assignment.id).text).to include("Assignment\nCourse 2: missing_assignment\nCourse 2")
      expect(todo_item(@missing_assignment.id).text).to include("Overdue | 10 points")

      expect(todo_item(@incomplete_discussion.id).text).to include("Discussion\nCourse 1: missing_graded_discussion\nCourse 1")
      expect(todo_item(@incomplete_discussion.id).text).to include("Overdue | 10 points")
    end

    it "displays announcements" do
      go_to_dashboard

      expect(todo_item(@announcement1.id).text).to include("Announcement\nCourse 1 - Announcement title 1\nCourse 1")
      expect(todo_item(@announcement1.id).text).to include("Posted ")
      expect(todo_item(@announcement2.id).text).to include("Announcement\nCourse 2 - Announcement title 2\nCourse 2")
      expect(todo_item(@announcement2.id).text).to include("Posted ")

      expect(todo_item(@announcement1.id).text).not_to include("due ")
      expect(todo_item(@announcement1.id).text).not_to include("points ")
    end
  end

  context "todo widget filtering" do
    it "can filter by Complete status" do
      go_to_dashboard

      filter_todos_by("Complete")
      expect(todo_item(@completed_discussion1.id)).to be_displayed
      expect(todo_item(@graded_assignment.id)).to be_displayed
      expect(todo_item(@completed_discussion2.id)).to be_displayed
      expect(todo_item(@submitted_assignment.id)).to be_displayed
      expect(todo_item(@graded_quiz.id)).to be_displayed
    end

    it "can filter by All status" do
      go_to_dashboard

      filter_todos_by("All")
      expect(todo_item(@completed_discussion1.id)).to be_displayed
      expect(todo_item(@incomplete_quiz.id)).to be_displayed
      expect(todo_item(@missing_assignment.id)).to be_displayed
      expect(todo_item(@graded_assignment.id)).to be_displayed
      expect(todo_item(@incomplete_discussion.id)).to be_displayed
    end

    it "filter selection persists across refresh" do
      go_to_dashboard

      filter_todos_by("Complete")
      refresh_page
      wait_for_ajaximations

      expect(todo_filter_select.attribute("value")).to eq("Complete")
    end

    it "marking item complete removes it from Incomplete filter" do
      skip "2026-02-11 Unskip after fix bug LX-3764"
      go_to_dashboard

      expect(todo_item(@missing_assignment.id)).to be_displayed
      expect(todo_checkbox(@missing_assignment.id)).to be_displayed
      todo_checkbox(@missing_assignment.id).click
      expect(element_exists?(todo_item_selector(@missing_assignment.id))).to be_falsey

      expect(todo_item(@incomplete_discussion.id)).to be_displayed
      expect(todo_checkbox(@incomplete_discussion.id)).to be_displayed
      todo_checkbox(@incomplete_discussion.id).click
      expect(element_exists?(todo_item_selector(@incomplete_discussion.id))).to be_falsey

      expect(todo_item(@incomplete_quiz.id)).to be_displayed
      expect(todo_checkbox(@incomplete_quiz.id)).to be_displayed
      todo_checkbox(@incomplete_quiz.id).click
      expect(element_exists?(todo_item_selector(@incomplete_quiz.id))).to be_falsey
    end

    it "marking item incomplete removes it from Complete filter" do
      skip "2026-02-11 Unskip after fix bug LX-3764"
      go_to_dashboard

      expect(todo_item(@graded_assignment.id)).to be_displayed
      expect(todo_checkbox(@graded_assignment.id)).to be_displayed
      todo_checkbox(@graded_assignment.id).click
      expect(element_exists?(todo_item_selector(@graded_assignment.id))).to be_falsey

      expect(todo_item(@completed_discussion1.id)).to be_displayed
      expect(todo_checkbox(@completed_discussion1.id)).to be_displayed
      todo_checkbox(@completed_discussion1.id).click
      expect(element_exists?(todo_item_selector(@completed_discussion1.id))).to be_falsey

      expect(todo_item(@graded_quiz.id)).to be_displayed
      expect(todo_checkbox(@graded_quiz.id)).to be_displayed
      todo_checkbox(@graded_quiz.id).click
      expect(element_exists?(todo_item_selector(@graded_quiz.id))).to be_falsey
    end
  end

  context "todo widget pagination" do
    before :once do
      pagination_submission_setup
    end

    it "maintains filter when changing pages" do
      go_to_dashboard

      filter_todos_by("All")
      expect(widget_pagination_button("To-do list", 2)).to be_displayed
      widget_pagination_button("To-do list", 2).click
      expect(todo_filter_select.attribute("value")).to eq("All")
    end

    it "resets to page 1 when changing filter" do
      go_to_dashboard

      expect(widget_pagination_button("To-do list", 2)).to be_displayed
      widget_pagination_button("To-do list", 2).click

      filter_todos_by("All")
      expect(all_todo_items.size).to be >= 1
    end
  end

  context "todo widget navigation" do
    it "clicking item title navigates to detail page" do
      go_to_dashboard

      expect(todo_item_title(@missing_assignment.id)).to be_displayed
      todo_item_title(@missing_assignment.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/assignments/#{@missing_assignment.id}")
    end

    it "clicking course name navigates to course page" do
      go_to_dashboard

      expect(todo_item_course_link(@missing_assignment.id)).to be_displayed
      todo_item_course_link(@missing_assignment.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}")
    end
  end
end
