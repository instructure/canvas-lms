# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe Types::RubricAssessmentRatingType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
  let_once(:student) { student_in_course(course:, active_all: true).user }
  let_once(:assignment) { assignment_model(course:) }
  let_once(:rubric) { rubric_for_course }
  let_once(:rubric_association) do
    rubric_association_model(
      context: course,
      rubric:,
      association_object: assignment,
      purpose: "grading"
    )
  end
  let!(:rubric_assessment) do
    rubric_assessment_model(
      user: student,
      assessor: teacher,
      rubric_association:,
      assessment_type: "grading"
    )
  end
  let(:learning_outcome) { outcome_model }
  let(:submission) { assignment.submissions.where(user: student).first }
  let(:submission_type) { GraphQLTypeTester.new(submission, current_user: teacher) }

  it "works" do
    expect(
      submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { _id } } }")
    ).to eq [rubric_assessment.data.map { |r| r[:id].to_s }]
  end

  describe "works for the field" do
    it "comments" do
      rubric_assessment.data[0][:comments] = "hello world"
      rubric_assessment.save!
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { comments } } }")
      ).to eq [["hello world"]]
    end

    it "criterion" do
      rubric_assessment.data[0][:comments] = "hello world"
      rubric_assessment.save!
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { criterion { _id } } } }")
      ).to eq [rubric.criteria.map { |c| c[:id].to_s }]
    end

    it "description" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { description } } }")
      ).to eq [rubric_assessment.data.pluck(:description)]
    end

    it "outcome" do
      rubric_assessment.data[0][:learning_outcome_id] = learning_outcome.id
      rubric_assessment.save!
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { outcome { _id } } } }")
      ).to eq [[learning_outcome.id.to_s]]
    end

    it "points" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { points } } }")
      ).to eq [rubric_assessment.data.pluck(:points)]
    end

    it "rubricAssessmentId" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { rubricAssessmentId } } }")
      ).to eq [[rubric_assessment.id.to_s]]
    end
  end

  describe "artifact_attempt" do
    it "returns the value when artifact_attempt is non-nil" do
      submission.update!(attempt: 2)
      rubric_assessment.reload
      rubric_assessment.update!(artifact_attempt: 2)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { artifactAttempt } } }")
      ).to eq [[2]]
    end

    it "returns zero when artifact_attempt is nil" do
      rubric_assessment.update!(artifact_attempt: nil)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { artifactAttempt } } }")
      ).to eq [[0]]
    end
  end
end
