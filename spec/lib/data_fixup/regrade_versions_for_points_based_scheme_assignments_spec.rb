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

describe DataFixup::RegradeVersionsForPointsBasedSchemeAssignments do
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
    assignment1.submit_homework(@student)
    assignment1.grade_student(@student, score: 8.998, grader: @teacher)
    assignment1.submit_homework(@student)
    assignment1.grade_student(@student, score: 8.999, grader: @teacher)
    @submission1 = assignment1.submissions.find_by(user: @student)
    submission1_current_version = @submission1.versions.find_by(number: 3)
    submission1_past_version = @submission1.versions.find_by(number: 2)
    submission1_current_version.update_columns(yaml: submission1_current_version.model.attributes.merge("grade" => "B", "published_grade" => "B").to_yaml)
    submission1_past_version.update_columns(yaml: submission1_past_version.model.attributes.merge("grade" => "B", "published_grade" => "B").to_yaml)
    @submission2 = assignment2.submit_homework(@student)
    @submission2.update!(score: 4.998)
    submission2_version = @submission2.versions.first
    yaml = submission2_version.model.attributes.merge("grade" => "F", "published_grade" => "F").to_yaml
    submission2_version.update_columns(yaml:)
    @submission3 = assignment3.submit_homework(@student)
    @submission3.update!(score: 8.998)
  end

  it "does not create new versions" do
    expect { DataFixup::RegradeVersionsForPointsBasedSchemeAssignments.run }.not_to change {
      @submission1.versions.count
    }
  end

  it "updates the grades on most recent versions of submissions with incorrect grades that use the points based grading standard" do
    expect { DataFixup::RegradeVersionsForPointsBasedSchemeAssignments.run }.to change {
      @submission1.versions.find_by(number: 3).model.grade
    }.from("B").to("A")
    expect(@submission1.versions.find_by(number: 3).model.published_grade).to eq("A")
  end

  it "does not modify past versions (only operates on the most recent version)" do
    expect { DataFixup::RegradeVersionsForPointsBasedSchemeAssignments.run }.not_to change {
      @submission1.versions.find_by(number: 2).model.grade
    }.from("B")
    expect(@submission1.versions.find_by(number: 2).model.published_grade).to eq("B")
  end

  it "updates the grades on most recent versions of submissions with incorrect grades that inherit the points based grading standard" do
    expect { DataFixup::RegradeVersionsForPointsBasedSchemeAssignments.run }.to change {
      submission_from_version = @submission2.reload.versions.first.model
      submission_from_version.grade
    }.from("F").to("D")
    expect(@submission2.reload.versions.first.model.published_grade).to eq("D")
  end

  it "should not update the versioned grades of submissions that use the points based grading standard with correct grades" do
    expect { DataFixup::RegradeVersionsForPointsBasedSchemeAssignments.run }.not_to change {
      submission_from_version = @submission3.reload.versions.first.model
      submission_from_version.grade
    }
    expect(@submission3.reload.versions.first.model.published_grade).to eq("A")
  end
end
