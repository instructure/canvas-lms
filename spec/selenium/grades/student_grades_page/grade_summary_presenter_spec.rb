# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
require_relative "../../helpers/gradebook_common"

describe GradeSummaryPresenter do
  include_context "in-process server selenium tests"
  include_context "reusable_gradebook_course"

  describe "deleted submissions", priority: "2" do
    it "navigates to grade summary page" do
      course_with_student_logged_in
      @teacher = User.create!
      @course.enroll_teacher(@teacher)

      a1, a2 = Array.new(2) { @course.assignments.create! points_possible: 10 }
      a1.grade_student @student, grade: 10, grader: @teacher
      a2.grade_student @student, grade: 10, grader: @teacher
      a2.destroy

      get "/courses/#{@course.id}/grades"
      expect(f("#grades_summary")).to be_displayed
    end
  end

  describe "grade summary page" do
    before do
      enroll_teacher_and_students
      @observed_courses = Array.new(2) { course_factory(active_course: true, active_all: true) }
      @observed_courses.each do |course|
        student_enrollment = course.enroll_student student
        student_enrollment.accept

        observer_enrollment = course.enroll_user(
          observer,
          "ObserverEnrollment",
          associated_user_id: student.id
        )
        observer_enrollment.accept
      end
    end

    let(:active_element) { driver.execute_script("return document.activeElement") }

    context "when :student_grade_summary_upgrade feature flag is OFF" do
      it "shows the courses dropdown when logged in as observer" do
        user_session(observer)
        get "/courses/#{@observed_courses.first.id}/grades"
        expect(f("#course_select_menu")).to be_displayed
      end

      it "maintains focus on show what-if/revert to original buttons", priority: 2 do
        student_submission.student_entered_score = 8
        student_submission.save!

        user_session(student)
        get "/courses/#{test_course.id}/grades"

        f("#student-grades-whatif button").click
        expect(active_element).to have_attribute("id", "revert-all-to-actual-score")

        f("#revert-all-to-actual-score").click
        expect(active_element).to have_class("btn revert_all_scores_link")
      end
    end

    context "when :student_grade_summary_upgrade feature flag is ON" do
      before do
        Account.site_admin.enable_feature! :student_grade_summary_upgrade
      end

      it "shows the courses dropdown to observers" do
        user_session(observer)
        get "/courses/#{@observed_courses.first.id}/grades"
        expect(f("#course_select_menu")).to be_displayed
      end

      it "shows grade summary even with deleted submissions" do
        # student, teacher, and test_course come from gradebook_common
        a1, a2 = Array.new(2) { test_course.assignments.create! points_possible: 10 }
        a1.grade_student student, grade: 10, grader: teacher
        a2.grade_student student, grade: 10, grader: teacher
        a2.destroy

        user_session student
        get "/courses/#{test_course.id}/grades"
        expect(f("#course_select_menu")).to be_displayed
      end
    end
  end
end
