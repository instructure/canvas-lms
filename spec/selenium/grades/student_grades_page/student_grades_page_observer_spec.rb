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

require_relative "../../common"

describe "gradebook" do
  include_context "in-process server selenium tests"

  context "as an observer" do
    before :once do
      @students = Array.new(2) { |i| user_factory(name: "Student #{i}", active_all: true) }
      @observer = user_factory(name: "Observer", active_all: true)
      @admin = account_admin_user

      @observed_courses = Array.new(2) { |i| course_factory(active_course: true, active_all: true, course_name: "OC#{i}") }
      @observed_courses.each_with_index do |course, index|
        course.enroll_user(@students[0], "StudentEnrollment", enrollment_state: "active")
        course.enroll_user(@students[1], "StudentEnrollment", enrollment_state: "active")
        course.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @students[0].id, enrollment_state: "active")
        course.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @students[1].id, enrollment_state: "active")
        a = course.assignments.create!(title: "#{course.name} assignment", points_possible: 10)
        a.grade_student(@students[0], grade: (10 - index).to_s, grader: @admin)
        a.grade_student(@students[1], grade: (8 - index).to_s, grader: @admin)
      end
      @observed_courses[0].assignments.create!(title: "DO NOT GRADE", points_possible: 20)
    end

    context "when user is not quantitative data restricted" do
      it "allows observer to see grade totals with and without ungraded assignments" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/"
        expect(f(".student_assignment.final_grade").text).to eq "Total\n100%\n10.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n100%\n10.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n100%\n10.00 / 10.00"

        f("#only_consider_graded_assignments_wrapper").click
        expect(f(".student_assignment.final_grade").text).to eq "Total\n33.33%\n10.00 / 30.00"
        expect(f("tr.group_total").text).to eq "Assignments\n33.33%\n10.00 / 30.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n33.33%\n10.00 / 30.00"
      end

      it "can change the student filter" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/"
        f("#student_select_menu").click
        fj("li:contains('Student 1')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f(".student_assignment.final_grade").text).to eq "Total\n80%\n8.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n80%\n8.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n80%\n8.00 / 10.00"
      end

      it "can change the course filter" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/"
        f("#course_select_menu").click
        fj("li:contains('OC1')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f(".student_assignment.final_grade").text).to eq "Total\n90%\n9.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n90%\n9.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n90%\n9.00 / 10.00"
      end

      it "respect selected user when changing course filter" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/#{@students[1].id}"
        f("#course_select_menu").click
        fj("li:contains('OC1')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f(".student_assignment.final_grade").text).to eq "Total\n70%\n7.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n70%\n7.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n70%\n7.00 / 10.00"
      end
    end

    context "when user is quantitative data restricted" do
      before :once do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @observed_courses.first.restrict_quantitative_data = true
        @observed_courses.first.save!
      end

      it "can toggle between using and not using ungraded assignments" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/"
        expect(f(".student_assignment.final_grade").text).to eq "Total: A"
        # TODO: wait for VICE-3594 before proceeding
        # verify assignment group total and course final total is also A
        # uncheck the use only graded assignments checkbox
        # verify students get the letter grade equivalent of 33%
      end

      it "can change the student filter" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/"
        f("#student_select_menu").click
        fj("li:contains('Student 1')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f(".student_assignment.final_grade").text).to eq "Total: B−"
        expect(f("tr[data-testid='total_row']").text).to eq "Total B−"
        expect(f("tr[data-testid='agtotal-Assignments']").text).to eq "Assignments B−"
      end

      it "can change the course filter" do
        user_session @observer
        # Going from a Non RQD to RQD course
        get "/courses/#{@observed_courses.last.id}/grades/"

        # Verify that non RQD Courses show non RQD grades
        expect(f(".student_assignment.final_grade").text).to eq "Total\n90%\n9.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n90%\n9.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n90%\n9.00 / 10.00"
        # Switch to RQD course
        f("#course_select_menu").click
        fj("li:contains('OC0')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        # Verify RQD grades are shown
        expect(f(".student_assignment.final_grade").text).to eq "Total: A"
        expect(f("tr[data-testid='total_row']").text).to eq "Total A"
        expect(f("tr[data-testid='agtotal-Assignments']").text).to eq "Assignments A"
      end

      it "keeps selected user when changing course filter" do
        user_session @observer
        get "/courses/#{@observed_courses.first.id}/grades/#{@students[1].id}"
        f("#course_select_menu").click
        fj("li:contains('OC1')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        # Verify that the selected user did not change, and the correct assignments are shown
        # Since the course went from RQD to a non-RQD course, the grades should be shown as percentages
        expect(f(".student_assignment.final_grade").text).to eq "Total\n70%\n7.00 / 10.00"
        expect(f("tr.group_total").text).to eq "Assignments\n70%\n7.00 / 10.00"
        expect(f("tr#submission_final-grade").text).to eq "Total\n70%\n7.00 / 10.00"
      end
    end
  end
end
