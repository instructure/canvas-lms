# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../pages/k5_grades_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../../grades/setup/gradebook_setup"
require_relative "../shared_examples/k5_subject_grades_shared_examples"

describe "student k5 course grades tab" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5GradesTabPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include GradebookSetup

  before :once do
    student_setup
  end

  before do
    user_session @student
  end

  context "subject grades shared examples" do
    it_behaves_like "k5 subject grades"
  end

  context "course grading differences" do
    let(:grading_standard) { create_grading_standard(@subject_course) }
    let(:scheme_subject_grade) { "You got this" }
    let(:student_score) { 75 }

    before :once do
      @assignment = create_and_submit_assignment(@subject_course, "Grading Standards Assignment", 1.day.ago(Time.zone.now), 100)
      @assignment.grade_student(@student, grader: @homeroom_teacher, score: student_score, points_deducted: 0)
    end

    it "shows a different grading standard for assignments" do
      @assignment.update!(grading_type: "letter_grade", grading_standard_id: grading_standard.id)

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include(scheme_subject_grade)
    end

    it "shows the total score as a percentage with the scheme in parens" do
      @subject_course.update!(grading_standard_enabled: true, grading_standard_id: grading_standard.id)

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_total.text).to include("#{student_score}.00% (#{scheme_subject_grade})")
    end

    it "shows a letter grade if selected for the assignment" do
      @assignment.update!(grading_type: "letter_grade")

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include("C")
    end

    it "shows a percentage grade if selected for the assignment" do
      @assignment.update!(grading_type: "percent")

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include("#{student_score}%")
    end
  end

  context "assignment groups" do
    before :once do
      @subject_course.require_assignment_group
      @ag1 = "AG 1"
      @ag2 = "AG 2"
      assignment_group1 = @subject_course.assignment_groups.create!(name: @ag1)
      assignment_group2 = @subject_course.assignment_groups.create!(name: @ag2)
      @assignment1 = create_and_submit_assignment(@subject_course, "Assignment 1", "a1d", 100)
      @assignment2 = create_and_submit_assignment(@subject_course, "Assignment 2", "a2d", 100)
      @assignment1.update!(assignment_group: assignment_group1)
      @assignment2.update!(assignment_group: assignment_group2)
    end

    it "shows different assignment groups for assignments in grades list" do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0]).to include_text(@ag1)
      expect(grades_assignments_list[1]).to include_text(@ag2)
    end

    it "can open assignments group dropdown and see assignment group-specific grades" do
      @assignment1.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)
      @assignment2.grade_student(@student, grader: @homeroom_teacher, score: "60", points_deducted: 0)

      get "/courses/#{@subject_course.id}#grades"

      click_assignment_group_toggle

      expect(assignment_group_totals.count).to eq 3
      expect(assignment_group_totals[0]).to include_text("Assignments: n/a")
      expect(assignment_group_totals[1]).to include_text("#{@ag1}: 90.00%")
      expect(assignment_group_totals[2]).to include_text("#{@ag2}: 60.00%")
    end
  end

  context "grading periods" do
    before :once do
      @course = @subject_course
      create_grading_periods("Fall Term")
      associate_course_to_term("Fall Term")
      @assignment = create_and_submit_assignment(@subject_course, "new assignment", "assignment submitted", 100)
      @assignment.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)
    end

    it "shows the current grading period grades" do
      get "/courses/#{@subject_course.id}#grades"

      expect(element_value_for_attr(course_grading_period, "value")).to eq("GP Current (Current)")
      expect(grades_total).to include_text("90.00%")
    end

    it "shows the grades for a different grading period" do
      @assignment.update!(due_at: 1.week.ago)
      @assignment.grade_student(@student, grader: @homeroom_teacher, score: "80", points_deducted: 0)

      get "/courses/#{@subject_course.id}#grades"

      click_option(course_grading_period_selector, "GP Ended")

      expect(element_value_for_attr(course_grading_period, "value")).to eq("GP Ended")
      expect(grades_total).to include_text("80.00%")
    end
  end

  context "new grade indicator" do
    it "shows new grade indicator the first time the grades tab is accessed after grading", custom_timeout: 25 do
      get "/courses/#{@subject_course.id}#grades"
      # Doing the get first, then creating the assignment and refreshing to get around a weird Jenkins
      # quirk that seems to be refreshing the page automatically on occasion.
      assignment = create_and_submit_assignment(@subject_course, "new assignment", "assignment submitted", 100)
      assignment.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)
      refresh_page

      expect(new_grade_badge).to be_displayed
    end
  end

  context "learning mastery gradebook" do
    before :once do
      turn_on_learning_mastery_gradebook
      add_and_assess_rubric_assignment
    end

    it "shows learning mastery gradebook tab on student subject grades tab when enabled" do
      get "/courses/#{@subject_course.id}#grades"

      expect(learning_mastery_tab).to be_displayed
      expect(assignments_tab).to be_displayed
    end

    it "brings up learning mastery grades when tab is clicked" do
      get "/courses/#{@subject_course.id}#grades"

      click_learning_mastery_tab

      expect(outcomes_group).to be_displayed
      expect(outcomes_group).to include_text(@subject_course.name)
      expect(outcomes_group).to include_text("1 of 1 Mastered")
    end
  end
end
