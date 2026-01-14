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

describe "student dashboard Course work widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup # Creates 2 courses and a student enrolled in both
    dashboard_course_assignment_setup # Add 11 assignments
    set_widget_dashboard_flag(feature_status: true)
  end

  before do
    user_session(@student)
  end

  context "course work widget smoke tests" do
    before :once do
      dashboard_course_submission_setup
    end

    it "can filter work items in not submitted" do
      go_to_dashboard
      expect(course_work_summary_stats("Due")).to be_displayed

      expect(all_course_work_items.size).to eq(3)
      expect(course_work_summary_stats("Due").text).to eq("3\nDue")
      expect(course_work_item(@due_assignment.id)).to be_displayed
      expect(course_work_item(@due_graded_discussion.id)).to be_displayed
      expect(course_work_item(@due_quiz.id)).to be_displayed
      expect(course_work_item_pill("due_soon", @due_assignment.id)).to be_displayed
      expect(course_work_item_pill("due_soon", @due_graded_discussion.id)).to be_displayed
      expect(course_work_item_pill("due_soon", @due_quiz.id)).to be_displayed
    end

    it "can filter work items in missing" do
      go_to_dashboard
      expect(course_work_summary_stats("Missing")).to be_displayed

      filter_course_work_by(:date, "Missing")
      expect(all_course_work_items.size).to eq(3)
      expect(course_work_summary_stats("Missing").text).to eq("3\nMissing")

      expect(course_work_item(@missing_graded_discussion.id)).to be_displayed
      expect(course_work_item(@missing_assignment.id)).to be_displayed
      expect(course_work_item(@missing_quiz.id)).to be_displayed
      expect(course_work_item_pill("missing", @missing_graded_discussion.id)).to be_displayed
      expect(course_work_item_pill("missing", @missing_assignment.id)).to be_displayed
      expect(course_work_item_pill("missing", @missing_quiz.id)).to be_displayed
    end

    it "can filter work items in submitted" do
      go_to_dashboard
      expect(course_work_summary_stats("Submitted")).to be_displayed

      filter_course_work_by(:date, "Submitted")
      expect(all_course_work_items.size).to eq(5)
      expect(course_work_summary_stats("Submitted").text).to eq("5\nSubmitted")

      expect(course_work_item(@submitted_assignment.id)).to be_displayed
      expect(course_work_item(@submitted_discussion.id)).to be_displayed
      expect(course_work_item(@graded_assignment.id)).to be_displayed
      expect(course_work_item(@graded_discussion.id)).to be_displayed
      expect(course_work_item(@graded_quiz.assignment_id)).to be_displayed
      expect(course_work_item_pill("submitted", @submitted_assignment.id)).to be_displayed
      expect(course_work_item_pill("late", @submitted_discussion.id)).to be_displayed
      expect(course_work_item_pill("late", @graded_assignment.id)).to be_displayed
      expect(course_work_item_pill("late", @graded_discussion.id)).to be_displayed
      expect(course_work_item_pill("submitted", @graded_quiz.assignment_id)).to be_displayed
    end

    it "can filter work items in course" do
      go_to_dashboard
      expect(course_work_summary_stats("Due")).to be_displayed

      filter_course_work_by(:course, @course2.name)
      expect(course_work_summary_stats("Due").text).to eq("0\nDue")
      expect(no_course_work_message).to be_displayed

      filter_course_work_by(:date, "Missing")
      expect(all_course_work_items.size).to eq(2)
      expect(course_work_summary_stats("Missing").text).to eq("2\nMissing")

      filter_course_work_by(:date, "Submitted")
      expect(all_course_work_items.size).to eq(2)
      expect(course_work_summary_stats("Submitted").text).to eq("2\nSubmitted")
    end

    it "navigates to the course work when clicking the item" do
      go_to_dashboard

      expect(course_work_item_link(@due_assignment.id)).to be_displayed
      course_work_item_link(@due_assignment.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/assignments/#{@due_assignment.id}")
    end

    it "navigates to the course when clicking go to course link" do
      go_to_dashboard

      expect(course_work_item_course_link(@due_assignment.id)).to be_displayed
      course_work_item_course_link(@due_assignment.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}")
    end

    it "displays course work in pagination" do
      @assignment1 = @course1.assignments.create!(name: "Course 1: assignment 1", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
      @assignment2 = @course1.assignments.create!(name: "Course 1: assignment 2", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
      @assignment3 = @course1.assignments.create!(name: "Course 1: assignment 3", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
      @assignment4 = @course1.assignments.create!(name: "Course 1: assignment 4", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")

      go_to_dashboard
      expect(course_work_summary_stats("Due")).to be_displayed

      expect(all_course_work_items.size).to eq(6)
      expect(course_work_summary_stats("Due").text).to eq("7\nDue")
      widget_pagination_button("Course work", "2").click
      expect(all_course_work_items.size).to eq(1)
    end
  end

  context "assignments workflow edge case" do
    before :once do
      workflow_edge_case_course_setup
    end

    before do
      user_session(@student3)
    end

    it "shows late but not-locked assignments in missing when 0 grade is applied due to late policy" do
      # Verify that student can see the assignment in missing when they can still submit it for late work
      @assignment_late_but_not_locked = @course4.assignments.create!(
        name: "Assignment Workflow Test",
        points_possible: 10,
        due_at: 2.days.ago.end_of_day,
        lock_at: 3.days.from_now.end_of_day,
        submission_types: "online_text_entry"
      )
      @course4.create_late_policy(missing_submission_deduction_enabled: true) # Applies 0 grade for late work

      go_to_dashboard
      filter_course_work_by(:date, "Missing")
      expect(course_work_item(@assignment_late_but_not_locked.id)).to be_displayed
      expect(course_work_item_pill("missing", @assignment_late_but_not_locked.id)).to be_displayed
      filter_course_work_by(:date, "Submitted")
      expect(element_exists?(course_work_item_selector(@assignment_late_but_not_locked.id))).to be_falsey
      filter_course_work_by(:date, "Not submitted")
      expect(element_exists?(course_work_item_selector(@assignment_late_but_not_locked.id))).to be_falsey
    end

    it "doesn't display unassigned assignment" do
      @assigned_assignment = @course4.assignments.create!(
        name: "Assignment assigned but will be unassigned",
        points_possible: 10,
        due_at: 2.days.from_now.end_of_day,
        only_visible_to_overrides: true,
        submission_types: "online_text_entry"
      )
      create_adhoc_override_for_assignment(@assigned_assignment, @student3)

      go_to_dashboard
      expect(course_work_item(@assigned_assignment.id)).to be_displayed
      @assigned_assignment.assignment_overrides.where(set_type: "ADHOC").destroy_all
      clear_local_storage

      go_to_dashboard
      expect(element_exists?(course_work_item_selector(@assigned_assignment.id))).to be_falsey
    end

    context "graded unsubmitted work" do
      # Verify that assignments that were never submitted but graded displays in submitted
      before :once do
        @graded_unsubmitted_future = @course4.assignments.create!(
          name: "Graded but Never Submitted (Future)",
          points_possible: 10,
          due_at: 2.days.from_now.end_of_day,
          submission_types: "online_text_entry"
        )
        @graded_unsubmitted_future.grade_student(@student3, grade: "8", grader: @teacher3)

        @graded_unsubmitted_overdue = @course4.assignments.create!(
          name: "Graded but Never Submitted (Overdue)",
          points_possible: 10,
          due_at: 2.days.ago.end_of_day,
          submission_types: "online_text_entry"
        )
        @graded_unsubmitted_overdue.grade_student(@student3, grade: "7", grader: @teacher3)
      end

      it "displays graded unsubmitted work only in submitted filter" do
        go_to_dashboard

        expect(no_course_work_message).to be_displayed
        expect(element_exists?(course_work_item_selector(@graded_unsubmitted_future.id))).to be_falsey
        expect(element_exists?(course_work_item_selector(@graded_unsubmitted_overdue.id))).to be_falsey

        filter_course_work_by(:date, "Submitted")
        expect(course_work_item(@graded_unsubmitted_future.id)).to be_displayed
        expect(course_work_item_pill("submitted", @graded_unsubmitted_future.id)).to be_displayed
        expect(course_work_item(@graded_unsubmitted_overdue.id)).to be_displayed
        expect(course_work_item_pill("submitted", @graded_unsubmitted_overdue.id)).to be_displayed

        filter_course_work_by(:date, "Missing")
        expect(element_exists?(course_work_item_selector(@graded_unsubmitted_future.id))).to be_falsey
        expect(element_exists?(course_work_item_selector(@graded_unsubmitted_overdue.id))).to be_falsey
      end

      it "maintains correct stats count for graded unsubmitted work" do
        go_to_dashboard

        expect(no_course_work_message).to be_displayed
        expect(course_work_summary_stats("Due").text).to eq("0\nDue")

        filter_course_work_by(:date, "Submitted")
        expect(all_course_work_items.size).to eq(2)
        expect(course_work_summary_stats("Submitted").text).to eq("2\nSubmitted")

        filter_course_work_by(:date, "Missing")
        expect(no_course_work_message).to be_displayed
        expect(course_work_summary_stats("Missing").text).to eq("0\nMissing")
      end
    end

    context "assignments due same day in submission status filter" do
      before :once do
        @due_this_morning = @course4.assignments.create!(
          name: "Due 2 Hours Ago",
          due_at: 2.hours.ago,
          points_possible: 10,
          submission_types: "online_text_entry"
        )

        @due_this_afternoon = @course4.assignments.create!(
          name: "Due in 2 Hours",
          due_at: 2.hours.from_now,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
      end

      it "maintains correct filter list for assignments due today" do
        go_to_dashboard

        expect(course_work_item(@due_this_afternoon.id)).to be_displayed
        expect(element_exists?(course_work_item_selector(@due_this_morning.id))).to be_falsey
        expect(course_work_summary_stats("Due").text).to eq("1\nDue")
        expect(course_work_item_pill("due_soon", @due_this_afternoon.id)).to be_displayed

        filter_course_work_by(:date, "Missing")
        expect(course_work_item(@due_this_morning.id)).to be_displayed
        expect(element_exists?(course_work_item_selector(@due_this_afternoon.id))).to be_falsey
        expect(course_work_summary_stats("Missing").text).to eq("1\nMissing")

        filter_course_work_by(:date, "Submitted")
        expect(element_exists?(course_work_item_selector(@due_this_morning.id))).to be_falsey
        expect(element_exists?(course_work_item_selector(@due_this_afternoon.id))).to be_falsey
      end

      it "maintains correct stats count for assignments due today" do
        go_to_dashboard

        filter_course_work_by(:date, "Submitted")
        expect(no_course_work_message).to be_displayed
        expect(course_work_summary_stats("Submitted").text).to eq("0\nSubmitted")

        filter_course_work_by(:date, "Not submitted")
        expect(all_course_work_items.size).to eq(1)
        expect(course_work_summary_stats("Due").text).to eq("1\nDue")

        filter_course_work_by(:date, "Missing")
        expect(all_course_work_items.size).to eq(1)
        expect(course_work_summary_stats("Missing").text).to eq("1\nMissing")
      end
    end
  end

  context "Course work widget pagination" do
    before :once do
      dashboard_course_submission_setup
      pagination_submission_setup # Creates 70 assignments
    end

    it "displays all pagination link on initial load" do
      go_to_dashboard

      expect(widget_pagination_button("Course work", "6")).to be_displayed
      widget_pagination_button("Course work", "6").click
      expect(widget_pagination_button("Course work", "1")).to be_displayed

      filter_course_work_by(:date, "Missing")
      expect(widget_pagination_button("Course work", "6")).to be_displayed
      widget_pagination_button("Course work", "6").click
      expect(widget_pagination_button("Course work", "1")).to be_displayed

      filter_course_work_by(:date, "Submitted")
      expect(widget_pagination_button("Course work", "4")).to be_displayed
      widget_pagination_button("Course work", "4").click
      expect(widget_pagination_button("Course work", "1")).to be_displayed
      widget_pagination_button("Course work", "1").click
      expect(widget_pagination_button("Course work", "4")).to be_displayed
    end

    it "maintains pagination when switching filters" do
      go_to_dashboard

      expect(widget_pagination_button("Course work", "6")).to be_displayed

      filter_course_work_by(:date, "Missing")
      expect(widget_pagination_button("Course work", "6")).to be_displayed

      filter_course_work_by(:date, "Submitted")
      expect(widget_pagination_button("Course work", "4")).to be_displayed
      widget_pagination_button("Course work", "4").click
      widget_pagination_button("Course work", "1").click
      expect(widget_pagination_button("Course work", "4")).to be_displayed

      filter_course_work_by(:date, "Not submitted")
      expect(widget_pagination_button("Course work", "6")).to be_displayed

      filter_course_work_by(:date, "Missing")
      expect(widget_pagination_button("Course work", "6")).to be_displayed
    end
  end
end
