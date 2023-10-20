# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative "../pages/student_planner_page"

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    course_with_teacher(active_all: true, new_user: true, course_name: "Planner Course")
    @student1 = User.create!(name: "Student 1")
    @course.enroll_student(@student1).accept!
  end

  before do
    user_session(@student1)
  end

  context "assignments" do
    before :once do
      @assignment = @course.assignments.create({
                                                 name: "Assignment 1",
                                                 due_at: 1.day.from_now,
                                                 submission_types: "online_text_entry"
                                               })
    end

    it "shows and navigates to assignments page from student planner", priority: "1" do
      go_to_list_view
      validate_object_displayed(@course_name, "Assignment")
      validate_link_to_url(@assignment, "assignments")
    end

    it "navigates to the assignment submissions page when they are submitted." do
      @assignment.submit_homework(@student1,
                                  submission_type: "online_text_entry",
                                  body: "Assignment submitted")
      go_to_list_view
      fj("button:contains('Show 1 completed item')").click
      validate_link_to_submissions(@assignment, @student1, "assignments")
    end

    it "enables the checkbox when an assignment is completed", priority: "1" do
      @assignment.submit_homework(@student1,
                                  submission_type: "online_text_entry",
                                  body: "Assignment submitted")
      go_to_list_view
      expect(planner_app_div).to contain_jqcss('span:contains("Show 1 completed item")')
    end

    it "shows submitted tag for assignments that have submissions", priority: "1" do
      @assignment.submit_homework(@student1, submission_type: "online_text_entry", body: "Assignment submitted")
      go_to_list_view

      # Student planner shows submitted assignments as completed. Expand to see the assignment
      expand_completed_item
      validate_pill("Submitted")
    end

    it "shows points possible for graded items only when restrict_quantitative_data? is falsy for user" do
      @assignment.points_possible = 150
      @assignment.save!
      gd_assignment = @course.assignments.create({ name: "my gd", due_at: 1.day.from_now, points_possible: "150" })
      gd = @course.discussion_topics.create!(
        user: @teacher,
        title: "graded discussion topic",
        message: "assignment topic message",
        assignment: gd_assignment
      )
      my_quiz = quiz_model(course: @course)
      my_quiz.generate_quiz_data
      my_quiz.due_at = 1.day.from_now
      my_quiz.save!
      my_quiz.quiz_questions.create!(
        question_data: {
          name: "Quiz Questions",
          question_type: "essay",
          question_text: "your essay",
          points_possible: 1
        }
      )
      my_quiz.generate_quiz_data
      my_quiz.workflow_state = "available"
      my_quiz.save!

      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # falsy setting
      Account.default.settings[:restrict_quantitative_data] = { value: false, locked: true }
      Account.default.save!

      go_to_list_view
      expect(fj("div.planner-item:contains('#{@assignment.name}') .PlannerItem-styles__score").text).to eq "150 PTS"
      expect(fj("div.planner-item:contains('#{gd.title}') .PlannerItem-styles__score").text).to eq "150 PTS"
      expect(fj("div.planner-item:contains('#{my_quiz.title}') .PlannerItem-styles__score").text).to eq "1 PTS"

      # now truthy setting
      Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
      Account.default.save!
      @course.restrict_quantitative_data = true
      @course.save!

      go_to_list_view
      expect(f("body")).not_to contain_jqcss(".PlannerItem-styles__score")
    end

    it "shows new grades tag for assignments that are graded", priority: "1" do
      @assignment.grade_student(@student1, grade: 10, grader: @teacher)
      go_to_list_view
      validate_pill("Graded")
      expect(planner_app_div).not_to include_text("Feedback") # graded != feedback
    end

    it "shows new feedback tag for assignments that has feedback", priority: "1" do
      @assignment.update_submission(@student1, { comment: "Good", author: @teacher })
      go_to_list_view
      validate_pill("Feedback")
    end

    it "ensures time zone changes update the planner items", priority: "1" do
      go_to_list_view
      time = calendar_time_string(@assignment.due_at).chop
      expect(course_assignment_by_due_at(time)).to be_displayed
      @student1.time_zone = "Asia/Tokyo"
      @student1.save!
      refresh_page

      # the users time zone is not converted to UTC and to balance it we subtract 6 hours from the due time
      time = calendar_time_string(@assignment.due_at + 9.hours).chop
      expect(course_assignment_by_due_at(time)).to be_displayed
    end

    it "shows missing tag for an assignment with missing submissions.", priority: "1" do
      @assignment.due_at = 2.weeks.ago
      @assignment.save!
      @course.assignments.create({
                                   name: "Assignment 2",
                                   due_at: 1.day.from_now,
                                   submission_types: "online_text_entry"
                                 })

      go_to_list_view
      force_click(load_prior_button_selector)
      expect(planner_app_div).to be_displayed
      expect(course_assignment_link(@course.name, planner_app_div)).to be_displayed
      validate_pill("Missing")
    end

    it "can follow course link to course", priority: "1" do
      go_to_list_view
      element = flnpt(@course[:name].upcase, planner_app_div)
      expect_new_page_load do
        element.click
      end
      expect(driver).not_to contain_css(".StudentPlanner__Container")
    end
  end
end
