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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::SaveRubricAssessment do
  before do
    setup_course_assessment
  end

  let(:context) { { current_user: @teacher, domain_root_account: @course.root_account } }

  describe "validations" do
    it "requires authorization" do
      student_context = { current_user: @student1, domain_root_account: @course.root_account }
      mutation = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading")
      )
      result = CanvasSchema.execute(mutation, context: student_context)
      expect(result["errors"]).to be_present
      expect(result["errors"].first["message"]).to eq("Not authorized to assess user")
    end
  end

  describe "invalid input ids" do
    it "returns errors if submission is not found" do
      mutation = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: "999",
        assessment_details: get_assessment_details("grading")
      )
      result = CanvasSchema.execute(mutation, context:)
      expect(result["errors"]).to be_present
      expect(result["errors"].first["message"]).to eq("Submission not found")
    end

    it "returns errors if rubric association is not found" do
      mutation = mutation_str(
        rubric_association_id: "999",
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading")
      )
      result = CanvasSchema.execute(mutation, context:)
      expect(result["errors"]).to be_present
      expect(result["errors"].first["message"]).to eq("RubricAssociation not found")
    end
  end

  describe "Assignment assessments" do
    it "saves new rubric assessment and returns updated submission" do
      expect(RubricAssessment.where(artifact_id: @student1_asset.id).count).to eq(0)
      mutation = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading")
      )
      result = CanvasSchema.execute(mutation, context:)
      expect(result["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result["data"]["saveRubricAssessment"]["submission"]["score"]).to eq(10)
      expect(result["data"]["saveRubricAssessment"]["submission"]["grade"]).to eq("10")
      expect(RubricAssessment.where(artifact_id: @student1_asset.id).count).to eq(1)

      rubric_assessments = RubricAssessment.where(artifact_id: @student1_asset.id)
      expect(rubric_assessments.count).to eq(1)
      expect(result["data"]["saveRubricAssessment"]["rubricAssessment"]["_id"]).to eq(rubric_assessments.first.id.to_s)
      expect(result["data"]["saveRubricAssessment"]["rubricAssessment"]["score"]).to eq(10)
    end

    it "saves an existing rubric assessment and returns updated submission" do
      RubricAssessment.create!({
                                 artifact: @student1_asset,
                                 assessment_type: "grading",
                                 assessor: @teacher,
                                 rubric: @rubric,
                                 user: @student1_asset.user,
                                 rubric_association: @rubric_association,
                                 data: [{ points: 3.0 }]
                               })
      expect(RubricAssessment.where(artifact_id: @student1_asset.id).count).to eq(1)
      mutation = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading")
      )
      result = CanvasSchema.execute(mutation, context:)
      expect(result["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result["data"]["saveRubricAssessment"]["submission"]["score"]).to eq(10)
      expect(result["data"]["saveRubricAssessment"]["submission"]["grade"]).to eq("10")

      rubric_assessments = RubricAssessment.where(artifact_id: @student1_asset.id)
      expect(rubric_assessments.count).to eq(1)
      expect(result["data"]["saveRubricAssessment"]["rubricAssessment"]["_id"]).to eq(rubric_assessments.first.id.to_s)
      expect(result["data"]["saveRubricAssessment"]["rubricAssessment"]["score"]).to eq(10)
    end

    it "follow:s actions from two teachers should only create one assessment" do
      mutation1 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading"),
        graded_anonymously: false
      )
      mutation2 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading"),
        graded_anonymously: false
      )
      result1 = CanvasSchema.execute(mutation1, context: { current_user: @teacher, domain_root_account: @course.root_account })
      result2 = CanvasSchema.execute(mutation2, context: { current_user: @teacher2, domain_root_account: @course.root_account })
      expect(result1["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result1["data"]["saveRubricAssessment"]["submission"]["score"]).to eq(10)
      expect(result1["data"]["saveRubricAssessment"]["submission"]["grade"]).to eq("10")
      expect(result2["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result2["data"]["saveRubricAssessment"]["submission"]["score"]).to eq(10)
      expect(result2["data"]["saveRubricAssessment"]["submission"]["grade"]).to eq("10")

      rubric_assessments = RubricAssessment.where(artifact_id: @student1_asset.id)
      expect(rubric_assessments.count).to eq(1)
      expect(rubric_assessments.first.assessor_id).to eq(@teacher2.id)
    end

    it "follow:s multiple peer reviews for the same submission should work fine" do
      mutation1 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("peer_review", 5),
        graded_anonymously: false
      )
      mutation2 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("peer_review", 10),
        graded_anonymously: false
      )
      result1 = CanvasSchema.execute(mutation1, context: { current_user: @student2, domain_root_account: @course.root_account })
      result2 = CanvasSchema.execute(mutation2, context: { current_user: @student3, domain_root_account: @course.root_account })
      expect(result1["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result1["data"]["saveRubricAssessment"]["submission"]["score"]).to be_nil
      expect(result1["data"]["saveRubricAssessment"]["submission"]["grade"]).to be_nil
      expect(result2["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result2["data"]["saveRubricAssessment"]["submission"]["score"]).to be_nil
      expect(result2["data"]["saveRubricAssessment"]["submission"]["grade"]).to be_nil

      rubric_assessments = RubricAssessment.where(artifact_id: @student1_asset.id)
      expect(rubric_assessments.count).to eq(2)
    end

    it "follow:s multiple peer reviews for the same submission should work fine, even with a teacher assessment in play" do
      mutation1 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("grading"),
        graded_anonymously: false
      )
      mutation2 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("peer_review", 5),
        graded_anonymously: false
      )
      mutation3 = mutation_str(
        rubric_association_id: @rubric_association.id,
        submission_id: @student1_asset.id,
        assessment_details: get_assessment_details("peer_review", 10),
        graded_anonymously: false
      )
      result1 = CanvasSchema.execute(mutation1, context: { current_user: @teacher, domain_root_account: @course.root_account })
      result2 = CanvasSchema.execute(mutation2, context: { current_user: @student2, domain_root_account: @course.root_account })
      result3 = CanvasSchema.execute(mutation3, context: { current_user: @student3, domain_root_account: @course.root_account })
      expect(result1["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result1["data"]["saveRubricAssessment"]["submission"]["score"]).to eq(10)
      expect(result1["data"]["saveRubricAssessment"]["submission"]["grade"]).to eq("10")
      expect(result2["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result2["data"]["saveRubricAssessment"]["submission"]["score"]).to be_nil
      expect(result2["data"]["saveRubricAssessment"]["submission"]["grade"]).to be_nil
      expect(result3["data"]["saveRubricAssessment"]["submission"]["_id"]).to eq(@student1_asset.id.to_s)
      expect(result3["data"]["saveRubricAssessment"]["submission"]["score"]).to be_nil
      expect(result3["data"]["saveRubricAssessment"]["submission"]["grade"]).to be_nil

      rubric_assessments = RubricAssessment.where(artifact_id: @student1_asset.id)
      expect(rubric_assessments.count).to eq(3)
    end
  end

  def get_assessment_details(assessment_type, points = 10)
    {
      "assessment_type" => assessment_type,
      "criterion_crit1" => {
        "points" => points,
        "comments" => "",
        "save_comment" => "0",
        "description" => "Good",
        "rating_id" => "rat1"
      }
    }
  end

  def mutation_str(rubric_association_id: nil, rubric_assessment_id: nil, submission_id: nil, assessment_details: {}, graded_anonymously: false, provisional: false)
    assessment_details_json = assessment_details.to_json.gsub('"', '\"')
    input_fields = [
      "rubricAssociationId: \"#{rubric_association_id}\"",
      "rubricAssessmentId: \"#{rubric_assessment_id}\"",
      "submissionId: \"#{submission_id}\"",
      "assessmentDetails: \"#{assessment_details_json}\"",
      "gradedAnonymously: #{graded_anonymously}",
      "provisional: #{provisional}"
    ].join("\n    ")

    <<~GQL
      mutation {
        saveRubricAssessment(input: {
          #{input_fields}
        }) {
          submission {
            _id
            score
            grade
          }
          rubricAssessment {
            _id
            score
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def setup_course_assessment
    course_with_teacher_logged_in(active_all: true)
    @student1 = User.create!(name: "student 1", workflow_state: "registered")
    @student2 = User.create!(name: "student 2", workflow_state: "registered")
    @student3 = User.create!(name: "student 3", workflow_state: "registered")
    @teacher2 = User.create!(name: "teacher 2", workflow_state: "registered")
    @course.enroll_student(@student1).accept!
    @course.enroll_student(@student2).accept!
    @course.enroll_student(@student3).accept!
    @course.enroll_teacher(@teacher2).accept!
    @assignment = @course.assignments.create!(title: "Some Assignment")
    rubric_assessment_model(user: @user, context: @course, association_object: @assignment, purpose: "grading")
    @student1_asset = @assignment.find_or_create_submission(@student1)
    @student2_asset = @assignment.find_or_create_submission(@student2)
    @student3_asset = @assignment.find_or_create_submission(@student3)
    @rubric_association.update!(use_for_grading: true)
    @rubric_association.assessment_requests.create!(user: @student1, asset: @student1_asset, assessor: @student2, assessor_asset: @student2_asset)
    @rubric_association.assessment_requests.create!(user: @student1, asset: @student1_asset, assessor: @student3, assessor_asset: @student3_asset)
  end
end
