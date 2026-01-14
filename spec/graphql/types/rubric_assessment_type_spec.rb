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

  context "with moderated grading" do
    let(:final_grader) { teacher_in_course(active_all: true, course:, name: "Final Grader").user }
    let(:other_grader) { teacher_in_course(active_all: true, course:, name: "Other Grader").user }

    before do
      @moderated_assignment = @course.assignments.create!(
        due_at: 2.years.from_now,
        final_grader:,
        grader_count: 2,
        moderated_grading: true,
        points_possible: 10,
        submission_types: :online_text_entry,
        title: "Moderated Assignment"
      )
      rubric = rubric_for_course
      rubric_association = rubric_association_model(
        context: @course,
        rubric:,
        association_object: @moderated_assignment,
        purpose: "grading"
      )
      @submission = @moderated_assignment.submit_homework(@student, body: "foo", submitted_at: 2.hours.ago)

      @moderated_assignment.ensure_grader_can_adjudicate(grader: final_grader, provisional: true, occupy_slot: true)
      @moderated_assignment.ensure_grader_can_adjudicate(grader: other_grader, provisional: true, occupy_slot: true)
      # ensuring the anonymous grader identities used for testing sake
      ModerationGrader.find_by(user_id: final_grader.id).update!(anonymous_id: "anon1")
      ModerationGrader.find_by(user_id: other_grader.id).update!(anonymous_id: "anon2")

      moderator_provisional_grade = @submission.find_or_create_provisional_grade!(final_grader)
      rubric_association.assess(
        user: @student,
        assessor: final_grader,
        artifact: moderator_provisional_grade,
        assessment: { assessment_type: "grading", criterion_crit1: { points: 5 } }
      )

      provisional_grade = @submission.find_or_create_provisional_grade!(other_grader)
      rubric_association.assess(
        user: @student,
        assessor: other_grader,
        artifact: provisional_grade,
        assessment: { assessment_type: "grading", criterion_crit1: { points: 5 } }
      )
    end

    it "returns anonymous grader identity to final grader when grader_names_visible_to_final_grader is false" do
      @moderated_assignment.update!(grader_names_visible_to_final_grader: false)
      final_grader_submission_type = GraphQLTypeTester.new(@submission, current_user: final_grader)
      result = final_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { assessor { name } } }"
      )

      assessor_names = result.compact
      expect(assessor_names).not_to be_empty
      expect(assessor_names).to include("Grader 2")
      expect(assessor_names).to include("Final Grader")
    end

    it "returns actual assessor to final grader when grader_names_visible_to_final_grader is true" do
      @moderated_assignment.update!(grader_names_visible_to_final_grader: true)
      final_grader_submission_type = GraphQLTypeTester.new(@submission, current_user: final_grader)
      result = final_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { assessor { name } } }"
      )

      expect(result).to include("Other Grader")
      expect(result).to include("Final Grader")
    end

    it "returns only accessor's own assessment when not the final grader" do
      @moderated_assignment.update!(grader_names_visible_to_final_grader: true)
      final_grader_submission_type = GraphQLTypeTester.new(@submission, current_user: other_grader)
      result = final_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { assessor { name } } }"
      )

      expect(result).to include("Other Grader")
      expect(result).not_to include("Final Grader")
    end

    it "returns isCurrentUser correctly for moderator and provisional graders" do
      @moderated_assignment.update!(grader_names_visible_to_final_grader: false)

      # Final grader should see their own assessment as isCurrentUser: true
      final_grader_submission_type = GraphQLTypeTester.new(@submission, current_user: final_grader)

      # Query isCurrentUser flags
      is_current_user_result = final_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { isCurrentUser } }"
      )
      expect(is_current_user_result.count).to eq(2)
      expect(is_current_user_result).to include(true)
      expect(is_current_user_result).to include(false)

      # Query assessor names
      assessor_names_result = final_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { assessor { name } } }"
      )
      expect(assessor_names_result).to include("Final Grader")
      expect(assessor_names_result).to include("Grader 2")

      # Other grader should only see their own assessment
      other_grader_submission_type = GraphQLTypeTester.new(@submission, current_user: other_grader)
      is_current_user_result = other_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { isCurrentUser } }"
      )
      expect(is_current_user_result.count).to eq(1)
      expect(is_current_user_result[0]).to be(true)

      assessor_name_result = other_grader_submission_type.resolve(
        "rubricAssessmentsConnection(filter: { includeProvisionalAssessments: true }) { nodes { assessor { name } } }"
      )
      expect(assessor_name_result[0]).to eq("Other Grader")
    end
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

      rubric_assessment.update(data: nil)
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { assessmentRatings { _id } } }")
      ).to eq [nil]
    end

    it "rubric_association" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { rubricAssociation { _id } } }")
      ).to eq [rubric_association.id.to_s]
    end

    it "updated_at" do
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { updatedAt } }")
      ).to eq [rubric_assessment.updated_at.iso8601]
    end

    it "is_current_user" do
      # teacher is the assessor, so isCurrentUser should be true when teacher is current_user
      expect(
        submission_type.resolve("rubricAssessmentsConnection { nodes { isCurrentUser } }")
      ).to eq [true]

      # student is not the assessor, so isCurrentUser should be false when student is current_user
      student_submission_type = GraphQLTypeTester.new(submission, current_user: student)
      expect(
        student_submission_type.resolve("rubricAssessmentsConnection { nodes { isCurrentUser } }")
      ).to eq [false]
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
