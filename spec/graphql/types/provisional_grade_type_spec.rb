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
#

require_relative "../graphql_spec_helper"

describe Types::ProvisionalGradeType do
  before(:once) do
    @teacher = user_factory(active_all: true)
    @student = user_factory(active_all: true)
    @moderator = user_factory(active_all: true)
    @course = course_factory(active_all: true)
    @course.enroll_teacher(@teacher, enrollment_state: "active")
    @course.enroll_student(@student, enrollment_state: "active")
    @course.enroll_teacher(@moderator, enrollment_state: "active")

    @assignment = @course.assignments.create!(
      name: "moderated assignment",
      moderated_grading: true,
      grader_count: 2,
      final_grader: @moderator
    )
    @assignment.grade_student(@student, grader: @teacher, provisional: true, score: 10)
    @provisional_grade = @assignment.provisional_grades.find_by(scorer: @teacher)
    @submission = @assignment.submissions.find_by!(user: @student)
    @selection = @assignment.moderated_grading_selections.find_by(student: @student)
  end

  let(:submission_type) { GraphQLTypeTester.new(@submission, current_user: @moderator, request: ActionDispatch::TestRequest.create) }

  it "works" do
    expect(submission_type.resolve("provisionalGradesConnection { nodes { _id } }")).to eq [@provisional_grade.id.to_s]
    expect(submission_type.resolve("provisionalGradesConnection { nodes { grade } }")).to eq [@provisional_grade.grade]
    expect(submission_type.resolve("provisionalGradesConnection { nodes { score } }")).to eq [@provisional_grade.score]
    expect(submission_type.resolve("provisionalGradesConnection { nodes { final } }")).to eq [@provisional_grade.final]
    expect(
      submission_type.resolve("provisionalGradesConnection { nodes { scorerAnonymousId } }")
    ).to eq [@assignment.moderation_graders.find_by(user_id: @provisional_grade.scorer_id).anonymous_id]
  end

  describe "selected" do
    it "return false if there is no selected provisional grade" do
      expect(submission_type.resolve("provisionalGradesConnection { nodes { selected } }")).to eq [false]
    end

    it "returns true if there is a selected provisional grade" do
      @selection.update!(provisional_grade: @provisional_grade)
      expect(submission_type.resolve("provisionalGradesConnection { nodes { selected } }")).to eq [true]
    end
  end
end
