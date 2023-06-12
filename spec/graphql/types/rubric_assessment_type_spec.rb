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

describe Types::RubricAssessmentType do
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
  let(:submission) { assignment.submissions.where(user: student).first }
  let(:submission_type) { GraphQLTypeTester.new(submission, current_user: teacher) }

  it "works" do
    expect(
      submission_type.resolve("rubricAssessmentsConnection { nodes { _id } }")
    ).to eq [rubric_assessment.id.to_s]
  end

  it "requires permission to see the assessor" do
    assignment.update(anonymous_peer_reviews: true)
    rubric_assessment.update(assessment_type: "no_reason")
    expect(
      submission_type.resolve(
        "rubricAssessmentsConnection { nodes { assessor { _id } } }",
        current_user: student
      )
    ).to eq [nil]
  end

  describe "works for the field" do
    it "assessment_type" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentType } }")
      ).to eq [rubric_assessment.assessment_type]
    end

    it "score" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { score } }")
      ).to eq [rubric_assessment.score]
    end

    it "user" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { user { _id } } }")
      ).to eq [student.id.to_s]
    end

    it "assessor" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessor { _id } } }")
      ).to eq [teacher.id.to_s]
    end

    it "assessment_ratings" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { _id } } }")
      ).to eq [rubric_assessment.data.map { |r| r[:id].to_s }]
    end

    it "rubric_association" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { rubricAssociation { _id } } }")
      ).to eq [rubric_association.id.to_s]
    end
  end

  describe "artifact_attempt" do
    it "returns the value when artifact_attempt is non-nil" do
      submission.update!(attempt: 2)
      rubric_assessment.reload
      rubric_assessment.update!(artifact_attempt: 2)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { artifactAttempt } }")
      ).to eq [2]
    end

    it "returns zero when artifact_attempt is nil" do
      rubric_assessment.update!(artifact_attempt: nil)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { artifactAttempt } }")
      ).to eq [0]
    end
  end
end
