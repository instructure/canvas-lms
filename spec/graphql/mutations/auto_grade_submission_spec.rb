# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::AutoGradeSubmission do
  before :once do
    course_with_teacher(active_all: true)
    @course.enable_feature!(:project_lhotse)
    @student = student_in_course(course: @course, active_all: true).user
    @assignment = assignment_model(course: @course)
    @submission = submission_model(
      user: @student,
      assignment: @assignment,
      body: "This is a valid essay submission.",
      submission_type: "online_text_entry"
    )
  end

  def execute_mutation(submission_id: @submission.id, current_user: @teacher)
    mutation_command = <<~GQL
      mutation {
        autoGradeSubmission(input: {
          submissionId: "#{submission_id}"
        }) {
          progress {
            _id
          }
          errors {
            message
          }
        }
      }
    GQL
    CanvasSchema.execute(mutation_command, context: { current_user:, request: ActionDispatch::TestRequest.create })
  end

  before do
    allow(Feature.definitions["project_lhotse"]).to receive(:visible_on).and_return(proc { true })
    allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive_messages(validate_assignment: [], validate_submission: [])
    @progress = @course.progresses.create!(tag: "auto_grade_submission", user: @student)
    mock_service = instance_double(AutoGradeOrchestrationService, auto_grade_in_background: @progress)
    allow(AutoGradeOrchestrationService).to receive(:new).and_return(mock_service)
  end

  describe "validation" do
    context "when both validators return no issues" do
      it "proceeds to grading" do
        result = execute_mutation
        expect(result.dig("data", "autoGradeSubmission", "errors")).to be_nil
        expect(result.dig("data", "autoGradeSubmission", "progress")).to be_present
      end
    end

    context "when validate_assignment returns an error issue" do
      it "raises an execution error with the assignment error message" do
        allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
          .and_return([{ level: "error", message: "No rubric is attached to this assignment." }])
        result = execute_mutation
        expect(result["errors"].first["message"]).to include("No rubric is attached to this assignment.")
      end
    end

    context "when validate_submission returns an error issue" do
      it "raises an execution error with the submission error message" do
        allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_submission)
          .and_return([{ level: "error", message: "No essay submission found." }])
        result = execute_mutation
        expect(result["errors"].first["message"]).to include("No essay submission found.")
      end
    end

    context "when both validators return error issues" do
      it "includes all error messages in the raised error" do
        allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive_messages(
          validate_assignment: [{ level: "error", message: "No rubric is attached to this assignment." }],
          validate_submission: [{ level: "error", message: "No essay submission found." }]
        )
        error_message = execute_mutation["errors"].first["message"]
        expect(error_message).to include("No rubric is attached to this assignment.")
        expect(error_message).to include("No essay submission found.")
      end
    end

    context "when validate_assignment returns multiple error issues" do
      it "includes all messages in the raised error" do
        allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
          .and_return([
                        { level: "error", message: "No rubric is attached to this assignment." },
                        { level: "error", message: "Grading assistance is not available right now." }
                      ])
        error_message = execute_mutation["errors"].first["message"]
        expect(error_message).to include("No rubric is attached to this assignment.")
        expect(error_message).to include("Grading assistance is not available right now.")
      end
    end

    context "when validate_assignment returns only a warning issue" do
      it "proceeds to grading - warnings do not block" do
        allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
          .and_return([{ level: "warning", message: "Some warning." }])
        result = execute_mutation
        expect(result.dig("data", "autoGradeSubmission", "errors")).to be_nil
        expect(result.dig("data", "autoGradeSubmission", "progress")).to be_present
      end
    end

    context "when validate_assignment returns a mix of error and warning" do
      it "raises with only the error message, not the warning" do
        allow(GraphQLHelpers::AutoGradeEligibilityHelper).to receive(:validate_assignment)
          .and_return([
                        { level: "error", message: "No rubric is attached to this assignment." },
                        { level: "warning", message: "Some warning." }
                      ])
        error_message = execute_mutation["errors"].first["message"]
        expect(error_message).to include("No rubric is attached to this assignment.")
        expect(error_message).not_to include("Some warning.")
      end
    end
  end

  context "when the feature flag is disabled" do
    before do
      @course.disable_feature!(:project_lhotse)
    end

    it "returns a GraphQL execution error about the disabled feature" do
      result = execute_mutation
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to include("Project Lhotse is not enabled")
    end
  end

  context "when the user lacks manage_grades permission" do
    it "returns an authorization error for a student" do
      result = execute_mutation(current_user: @student)
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to include("not found")
    end
  end

  context "when the submission is not found" do
    it "returns an error for an invalid submission id" do
      result = execute_mutation(submission_id: 0)
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to include("unexpected")
    end
  end

  context "background job enqueuing" do
    it "calls auto_grade_in_background with the correct submission" do
      mock_service = instance_double(AutoGradeOrchestrationService)
      allow(AutoGradeOrchestrationService).to receive(:new).and_return(mock_service)
      expect(mock_service)
        .to receive(:auto_grade_in_background)
        .with(submission: @submission)
        .and_return(@progress)

      execute_mutation
    end
  end

  context "with a relay-encoded submission ID" do
    it "resolves correctly and returns a progress object" do
      relay_id = GraphQL::Schema::UniqueWithinType.encode("Submission", @submission.id)
      result = execute_mutation(submission_id: relay_id)
      expect(result.dig("data", "autoGradeSubmission", "errors")).to be_nil
      expect(result.dig("data", "autoGradeSubmission", "progress")).to be_present
    end
  end

  context "when the orchestration service raises an unexpected exception" do
    before do
      exploding_service = instance_double(AutoGradeOrchestrationService)
      allow(exploding_service).to receive(:auto_grade_in_background).and_raise(RuntimeError, "unexpected error")
      allow(AutoGradeOrchestrationService).to receive(:new).and_return(exploding_service)
    end

    it "wraps the exception in a GraphQL execution error" do
      result = execute_mutation
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to eq("An unexpected error occurred while grading.")
    end
  end

  context "when the course is not found" do
    before do
      fake_assignment = instance_double(Assignment, course: nil)
      fake_submission = instance_double(
        Submission,
        id: @submission.id,
        assignment: fake_assignment
      )
      allow(Submission).to receive(:find).and_return(fake_submission)
    end

    it "returns a GraphQL execution error about the missing course" do
      result = execute_mutation
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to eq("An unexpected error occurred while grading.")
    end
  end
end
