# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/student_grades_page"

describe "gradebook - logged in as a student" do
  include_context "in-process server selenium tests"

  # Helpers
  def backend_group_helper
    Factories::GradingPeriodGroupHelper.new
  end

  def backend_period_helper
    Factories::GradingPeriodHelper.new
  end

  context "when :student_grade_summary_upgrade feature flag is OFF" do
    context "total point displays" do
      before(:once) do
        course_with_student({ active_course: true, active_enrollment: true })
        @teacher = User.create!
        @course.enroll_teacher(@teacher)
        @assignment = @course.assignments.build(points_possible: 20)
        @assignment.publish
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        @assignment.assignment_group.update(group_weight: 1)
        @course.show_total_grade_as_points = true
        @course.save!
      end

      it 'displays total and "out of" point values' do
        user_session(@student)
        StudentGradesPage.visit_as_student(@course)
        expect(StudentGradesPage.final_grade).to include_text("10")
        expect(StudentGradesPage.final_points_possible).to include_text("10.00 / 20.00")
      end

      it "displays both score and letter grade when course uses a grading scheme" do
        @course.update_attribute :grading_standard_id, 0 # the default
        @course.save!

        user_session(@student)
        StudentGradesPage.visit_as_student(@course)
        expect(f("div.final_grade").text).to eq "Total: 10.00 / 20.00 (F)"
        expect(f("tr.group_total").text).to eq "Assignments\n50%\n10.00 / 20.00"
      end

      it "respects grade dropping rules" do
        ag = @assignment.assignment_group
        ag.update(rules: "drop_lowest:1")
        ag.save!

        undropped = @course.assignments.build(points_possible: 20)
        undropped.publish
        undropped.grade_student(@student, grade: 20, grader: @teacher)
        user_session(@student)
        StudentGradesPage.visit_as_student(@course)
        expect(f("tr#submission_#{@assignment.id}").attribute("title")).to eq "This assignment is dropped and will not be considered in the total calculation"
        expect(f("div.final_grade").text).to eq "Total: 20.00 / 20.00"
        expect(f("tr.group_total").text).to eq "Assignments\n100%\n20.00 / 20.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n20.00 / 20.00\n20.00 / 20.00"
      end
    end

    context "when testing multiple courses" do
      it "can switch between courses" do
        admin = account_admin_user
        my_student = user_factory(name: "My Student", active_all: true)
        student_courses = Array.new(2) { |i| course_factory(active_course: true, active_all: true, course_name: "SC#{i}") }
        student_courses.each_with_index do |course, index|
          course.enroll_user(my_student, "StudentEnrollment", enrollment_state: "active")
          a = course.assignments.create!(title: "#{course.name} assignment", points_possible: 10)
          a.grade_student(my_student, grade: (10 - index).to_s, grader: admin)
        end

        user_session my_student
        StudentGradesPage.visit_as_student(student_courses[0])
        expect(f(".student_assignment.final_grade").text).to eq "Total\n100%\n10.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n100%\n10.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n100%\n10.00 / 10.00"

        f("#course_select_menu").click
        fj("li:contains('SC1')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f(".student_assignment.final_grade").text).to eq "Total\n90%\n9.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n90%\n9.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n90%\n9.00 / 10.00"
      end
    end

    context "when testing grading periods" do
      before(:once) do
        account_admin_user({ active_user: true })
        course_with_teacher({ user: @user, active_course: true, active_enrollment: true })
        student_in_course
      end

      context "with one past and one current period" do
        past_period_name = "Past Grading Period"
        current_period_name = "Current Grading Period"
        past_assignment_name = "Past Assignment"
        current_assignment_name = "Current Assignment"

        before do
          # create term
          term = @course.root_account.enrollment_terms.create!
          @course.update(enrollment_term: term)

          # create group and periods
          group = backend_group_helper.create_for_account(@course.root_account)
          term.update_attribute(:grading_period_group_id, group)
          backend_period_helper.create_with_weeks_for_group(group, 4, 2, past_period_name)
          backend_period_helper.create_with_weeks_for_group(group, 1, -3, current_period_name)

          # create assignments
          @course.assignments.create!(due_at: 3.weeks.ago, title: past_assignment_name)
          @course.assignments.create!(due_at: 1.week.from_now, title: current_assignment_name)

          # go to student grades page
          user_session(@teacher)
          StudentGradesPage.visit_as_teacher(@course, @student)
        end

        it "only shows assignments that belong to the selected grading period", priority: "1" do
          StudentGradesPage.select_period_by_name(past_period_name)
          expect_new_page_load { StudentGradesPage.click_apply_button }
          expect(StudentGradesPage.assignment_titles).to include(past_assignment_name)
          expect(StudentGradesPage.assignment_titles).not_to include(current_assignment_name)
        end
      end
    end
  end

  context "when student is quantitative data restricted" do
    before :once do
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # truthy setting
      Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
      Account.default.save!
    end

    it "does not show quantitative data" do
      course_with_teacher(name: "Dedicated Teacher", active_course: true, active_user: true)
      course_with_student(course: @course, name: "Hardworking Student", active_all: true)

      future_period_name = "Future Grading Period"
      current_period_name = "Current Grading Period"
      future_assignment_name = "Future Assignment"
      current_assignment_name = "Current Assignment"

      # create term
      term = @course.root_account.enrollment_terms.create!
      @course.update(enrollment_term: term)

      # create group and periods
      group = backend_group_helper.create_for_account(@course.root_account)
      group.update(display_totals_for_all_grading_periods: true)
      group.save!
      term.update_attribute(:grading_period_group_id, group)
      future_period = backend_period_helper.create_with_weeks_for_group(group, -8, -12, future_period_name)
      current_period = backend_period_helper.create_with_weeks_for_group(group, 1, -3, current_period_name)

      # create assignments
      future_assignment = @course.assignments.create!(due_at: 10.weeks.from_now, title: future_assignment_name, grading_type: "points", points_possible: 10)
      current_assignment = @course.assignments.create!(due_at: 1.week.from_now, title: current_assignment_name, grading_type: "points", points_possible: 10)

      future_assignment.grade_student(@student, grade: "10", grader: @teacher)
      current_assignment.grade_student(@student, grade: "8", grader: @teacher)

      user_session(@student)
      StudentGradesPage.visit_as_student(@course)
      ffj("tr:contains('Assignments')")

      current_assignment_selector = "tr:contains('#{current_assignment_name}')"
      future_assignment_selector = "tr:contains('#{future_assignment_name}')"

      # the all the grades and grading period selected is based on current period
      expect(f("#grading_period_select_menu").attribute(:value)).to eq current_period_name
      expect(f("div.final_grade").text).to eq "Total: B-"
      expect(fj(current_assignment_selector).text).to include "GRADED\nB-\nYour grade has been updated"
      expect(f("tr[data-testid='agtotal-Assignments']").text).to eq "Assignments B-"
      expect(f("tr[data-testid='total_row']").text).to eq "Total B-"
      expect(f("body")).not_to contain_jqcss(future_assignment_selector)

      # switch to future grading period and check that everything is based on the future period
      f("#grading_period_select_menu").click
      fj("li:contains('#{future_period_name}')").click
      fj("button:contains('Apply')").click
      wait_for_ajaximations
      expect(f("div.final_grade").text).to eq "Total: A"
      expect(fj(future_assignment_selector).text).to include "GRADED\nA\nYour grade has been updated"
      expect(f("tr[data-testid='agtotal-Assignments']").text).to eq "Assignments A"
      expect(f("tr[data-testid='total_row']").text).to eq "Total A"
      expect(f("body")).not_to contain_jqcss(current_assignment_selector)

      # switch to all grading periods and verify everything is based on all periods
      f("#grading_period_select_menu").click
      fj("li:contains('All Grading Periods')").click
      fj("button:contains('Apply')").click
      wait_for_ajaximations

      expect(fj(future_assignment_selector).text).to include "GRADED\nA\nYour grade has been updated"
      expect(fj(current_assignment_selector).text).to include "GRADED\nB-\nYour grade has been updated"

      # Make sure the grading period totals show because display_totals_for_all_grading_periods is true
      expect(fj("tr[data-testid='gradingPeriod-#{future_period.id}']").text).to eq "Future Grading Period A"
      expect(fj("tr[data-testid='gradingPeriod-#{current_period.id}']").text).to eq "Current Grading Period B-"

      group.update(display_totals_for_all_grading_periods: false)
      group.save!

      StudentGradesPage.visit_as_student(@course)

      f("#grading_period_select_menu").click
      fj("li:contains('All Grading Periods')").click
      fj("button:contains('Apply')").click
      wait_for_ajaximations

      # Make sure the grading period totals aren't shown because display_totals_for_all_grading_periods was changed to false
      expect(f("body")).not_to contain_jqcss("tr[data-testid='gradingPeriod-#{future_period.id}']")
      expect(f("body")).not_to contain_jqcss("tr[data-testid='gradingPeriod-#{current_period.id}']")
    end

    it "displays N/A in the total sidebar when no asignments have been graded" do
      course_with_teacher(name: "Dedicated Teacher", active_course: true, active_user: true)
      course_with_student(course: @course, name: "Hardworking Student", active_all: true)
      @course.assignments.create!(due_at: 1.week.from_now, title: "Current Assignment", grading_type: "points", points_possible: 10)
      user_session(@student)
      get "/courses/#{@course.id}/grades/#{@student.id}"

      expect(f(".final_grade").text).to eq("Total: N/A")
    end
  end
end
