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

require "spec_helper"

describe Gradebook::FinalGradeOverrides do
  let(:final_grade_overrides) { Gradebook::FinalGradeOverrides.new(@course, @teacher).to_h }

  before(:once) do
    @course = Course.create!
    @course.enable_feature!(:final_grades_override)

    grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
    @course.enrollment_term.grading_period_group = grading_period_group
    @course.enrollment_term.save!

    @grading_period_1 = grading_period_group.grading_periods.create!(
      end_date: 1.month.from_now,
      start_date: 1.month.ago,
      title: "Q1"
    )
    @grading_period_2 = grading_period_group.grading_periods.create!(
      end_date: 2.months.from_now,
      start_date: 1.month.from_now,
      title: "Q2"
    )

    @teacher = teacher_in_course(course: @course, active_all: true).user

    @student_enrollment_1 = student_in_course(active_all: true, course: @course)
    @student_enrollment_2 = student_in_course(active_all: true, course: @course)
    @test_student_enrollment = course_with_user('StudentViewEnrollment', course: @course, active_all: true)

    @student_1 = @student_enrollment_1.user
    @student_2 = @student_enrollment_2.user
    @test_student = @test_student_enrollment.user

    @assignment = assignment_model(course: @course, points_possible: 10)
    @assignment.grade_student(@student_1, grade: '85%', grader: @teacher)
    @assignment.grade_student(@student_2, grade: '85%', grader: @teacher)
    @assignment.grade_student(@test_student, grade: '85%', grader: @teacher)
  end

  it "includes user ids for each user with an overridden course grade" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_2.scores.find_by!(course_score: true).update!(override_score: 9.1)
    expect(final_grade_overrides.keys).to match_array([@student_1.id, @student_2.id])
  end

  it "includes the overridden course grade for the user" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    expect(final_grade_overrides[@student_1.id]).to have_key(:course_grade)
  end

  it "includes the percentage on the overridden course grade" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes the overridden grading period grades for the user" do
    @student_enrollment_1.scores.find_by!(grading_period: @grading_period_1).update!(override_score: 89.1)
    expect(final_grade_overrides[@student_1.id][:grading_period_grades]).to have_key(@grading_period_1.id)
  end

  it "includes the percentage on overridden grading period grades" do
    @student_enrollment_1.scores.find_by!(grading_period: @grading_period_1).update!(override_score: 89.1)
    grading_period_overrides = final_grade_overrides[@student_1.id][:grading_period_grades]
    expect(grading_period_overrides[@grading_period_1.id][:percentage]).to equal(89.1)
  end

  it "includes scores for inactive students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.deactivate
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes scores for concluded students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.conclude
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes scores for invited students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.update_attributes(workflow_state: "invited", last_activity_at: nil)
    expect(final_grade_overrides[@student_1.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "includes scores for test students" do
    @test_student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @test_student_enrollment.update_attributes(workflow_state: "invited", last_activity_at: nil)
    expect(final_grade_overrides[@test_student.id][:course_grade][:percentage]).to equal(89.1)
  end

  it "excludes scores for deleted students" do
    @student_enrollment_1.scores.find_by!(course_score: true).update!(override_score: 89.1)
    @student_enrollment_1.update_attributes(workflow_state: "deleted")
    expect(final_grade_overrides).not_to have_key(@student_1.id)
  end

  it "returns an empty map when no students were given final grade overrides" do
    expect(final_grade_overrides).to be_empty
  end
end
