# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::UpdatePointsBasedSchemeGradeChangeRecords do
  before do
    course_with_teacher(active_all: true)
    user_session(@teacher)

    @student = User.create!
    @course.enroll_student(@student, enrollment_state: "active")
    points_based_grading_standard = GradingStandard.create!(
      context: @course.account,
      title: "My Grading Standard",
      points_based: true,
      data: { "A" => 0.90, "B" => 0.80, "C" => 0.70, "D" => 0.50, "F" => 0.0 },
      scaling_factor: 10.0
    )
    @course.update!(grading_standard_id: points_based_grading_standard.id)
    assignment1 = @course.assignments.create!(grading_standard_id: points_based_grading_standard.id, points_possible: 10, grading_type: "letter_grade")
    @submission1 = assignment1.submit_homework(@student)
    assignment1.grade_student(@student, score: 8.998, grader: @teacher)
  end

  it "updates the grade change records for submissions that use the points based grading standard with incorrect grades" do
    @submission1.auditor_grade_change_records.update_all(grade_after: "B")
    expect { DataFixup::UpdatePointsBasedSchemeGradeChangeRecords.run }.to change {
      [@submission1.auditor_grade_change_records.count, @submission1.auditor_grade_change_records.take.grade_after]
    }.from([1, "B"]).to([1, "A"])
  end

  it "only modifies the most recent grade change record" do
    @submission1.assignment.grade_student(@student, score: 8.999, grader: @teacher)
    @submission1.auditor_grade_change_records.update_all(grade_after: "B")
    expect { DataFixup::UpdatePointsBasedSchemeGradeChangeRecords.run }.to change {
      [@submission1.auditor_grade_change_records.count, @submission1.auditor_grade_change_records.order(:created_at).pluck(:grade_after, :submission_version_number)]
    }.from([2, [["B", 1], ["B", 2]]]).to([2, [["B", 1], ["A", 2]]])
  end

  it "gracefully handles grade change records not existing" do
    @submission1.auditor_grade_change_records.delete_all
    expect { DataFixup::UpdatePointsBasedSchemeGradeChangeRecords.run }.not_to raise_error
  end

  it "does not modify grade change records where the score_after does not match the submission score" do
    @submission1.auditor_grade_change_records.update_all(grade_after: "B", score_after: 123.0)
    expect { DataFixup::UpdatePointsBasedSchemeGradeChangeRecords.run }.not_to change {
      [@submission1.auditor_grade_change_records.count, @submission1.auditor_grade_change_records.take.grade_after]
    }.from([1, "B"])
  end

  it "handles 0 point assignments using points-based grading standards" do
    @submission1.assignment.update!(points_possible: 0)
    @submission1.assignment.grade_student(@student, grade: "B", grader: @teacher)
    expect { DataFixup::UpdatePointsBasedSchemeGradeChangeRecords.run }.not_to change {
      [@submission1.auditor_grade_change_records.count, @submission1.auditor_grade_change_records.last.grade_after]
    }.from([2, "B"])
  end
end
