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

require_relative "../graphql_spec_helper"

describe Mutations::SubmitAutoGradeFeedback do
  before :once do
    course_with_teacher(active_all: true)
    @student = student_in_course(course: @course, active_all: true).user
  end

  let(:response_id) { "abc-123" }
  let(:cedar_response) do
    instance_double(InstructureMiscPlugin::Extensions::CedarClient::SubmitFeedbackResponse,
                    response_id:)
  end

  before do
    @course.enable_feature!(:project_lhotse)
    allow(Feature.definitions["project_lhotse"]).to receive(:visible_on).and_return(proc { true })
    stub_const("CedarClient", class_double(CedarClient))
    allow(CedarClient).to receive(:submit_feedback).and_return(cedar_response)
  end

  def execute_mutation(
    course_id: @course.id,
    response_id: self.response_id,
    feedback_type: "positive",
    comment: nil,
    current_user: @teacher
  )
    comment_arg = comment ? ", comment: \"#{comment}\"" : ""
    mutation_command = <<~GQL
      mutation {
        submitAutoGradeFeedback(input: {
          courseId: "#{course_id}"
          responseId: "#{response_id}"
          feedbackType: #{feedback_type}#{comment_arg}
        }) {
          responseId
          errors {
            message
          }
        }
      }
    GQL
    CanvasSchema.execute(
      mutation_command,
      context: { current_user:, request: ActionDispatch::TestRequest.create }
    )
  end

  describe "successful feedback submission" do
    it "returns the response_id from Cedar" do
      result = execute_mutation
      expect(result.dig("data", "submitAutoGradeFeedback", "responseId")).to eql(response_id)
    end

    it "calls CedarClient.submit_feedback with the correct arguments" do
      execute_mutation(feedback_type: "negative", comment: "Not helpful")
      expect(CedarClient).to have_received(:submit_feedback).with(
        response_id:,
        feedback_type: "negative",
        feature_slug: "grading-assistance-feedback",
        root_account_uuid: @course.account.root_account.uuid,
        current_user: @teacher,
        comment: "Not helpful"
      )
    end

    it "passes nil comment when not provided" do
      execute_mutation
      expect(CedarClient).to have_received(:submit_feedback).with(
        hash_including(comment: nil)
      )
    end

    it "resolves a relay-encoded course ID" do
      relay_id = GraphQL::Schema::UniqueWithinType.encode("Course", @course.id)
      result = execute_mutation(course_id: relay_id)
      expect(result.dig("data", "submitAutoGradeFeedback", "responseId")).to eql(response_id)
    end
  end

  context "when the feature flag is disabled" do
    before { @course.disable_feature!(:project_lhotse) }

    it "returns a GraphQL execution error" do
      result = execute_mutation
      expect(result["errors"].first["message"]).to include("Grading Assistance is not enabled")
    end
  end

  context "when the user lacks manage_grades permission" do
    it "returns an authorization error for a student" do
      result = execute_mutation(current_user: @student)
      expect(result["errors"].first["message"]).to include("not found")
    end
  end

  context "when the course is not found" do
    it "returns an unexpected error" do
      result = execute_mutation(course_id: 0)
      expect(result["errors"].first["message"]).to include("unexpected error occurred while submitting feedback")
    end
  end

  context "when CedarClient raises an error" do
    before do
      allow(CedarClient).to receive(:submit_feedback)
        .and_raise(StandardError, "Cedar unavailable")
    end

    it "returns a generic GraphQL execution error" do
      result = execute_mutation
      expect(result["errors"].first["message"]).to include("unexpected error occurred while submitting feedback")
    end
  end

  context "when an unexpected error is raised" do
    before do
      allow(CedarClient).to receive(:submit_feedback).and_raise(RuntimeError, "boom")
    end

    it "returns a generic GraphQL execution error" do
      result = execute_mutation
      expect(result["errors"].first["message"]).to include("unexpected error occurred while submitting feedback")
    end
  end
end
