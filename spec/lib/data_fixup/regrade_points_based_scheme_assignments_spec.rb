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

describe DataFixup::RegradePointsBasedSchemeAssignments do
  before do
    course_with_teacher(active_all: true)
    user_session(@teacher)

    @student = User.create!
    @course.enroll_student(@student, enrollment_state: "active")
    points_based_grading_standard = GradingStandard.create!(context: @course.account, title: "My Grading Standard", points_based: true, data: { "A" => 0.90, "B" => 0.80, "C" => 0.70, "D" => 0.50, "F" => 0.0 }, scaling_factor: 10.0)
    @course.update!(grading_standard_id: points_based_grading_standard.id)
    assignment1 = @course.assignments.create!(grading_standard_id: points_based_grading_standard.id, points_possible: 10, grading_type: "letter_grade")
    assignment2 = @course.assignments.create!(grading_standard_id: nil, points_possible: 10, grading_type: "gpa_scale")
    assignment3 = @course.assignments.create!(grading_standard_id: points_based_grading_standard.id, points_possible: 10, grading_type: "letter_grade")
    @submission1 = assignment1.submit_homework(@student)
    @submission1.update!(score: 8.998)
    @submission1.update_columns(grade: "B", published_grade: "B")
    @submission2 = assignment2.submit_homework(@student)
    @submission2.update!(score: 4.998)
    @submission2.update_columns(grade: "F", published_grade: "F")
    @submission3 = assignment3.submit_homework(@student)
    @submission3.update!(score: 8.998)
    @submission3.update_columns(grade: "A", published_grade: "A")
  end

  it "should update the grades of submissions that use the points based grading standard with incorrect grades" do
    expect { DataFixup::RegradePointsBasedSchemeAssignments.run }.to change {
      @submission1.reload.grade
    }.from("B").to("A")
    expect(@submission1.reload.published_grade).to eq("A")
  end

  it "should update the grades of submissions that inherit the points based grading standard with incorrect grades" do
    expect { DataFixup::RegradePointsBasedSchemeAssignments.run }.to change {
      @submission2.reload.grade
    }.from("F").to("D")
    expect(@submission2.reload.published_grade).to eq("D")
  end

  it "should not update the grades of submissions that use the points based grading standard with correct grades" do
    expect { DataFixup::RegradePointsBasedSchemeAssignments.run }.not_to change {
      @submission3.reload.grade
    }
    expect(@submission3.reload.published_grade).to eq("A")
  end
end
