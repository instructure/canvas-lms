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

describe AiExperiences::ConversationEvaluationService do
  let(:account) { account_model }
  let(:conversation_id) { "test-conversation-id" }
  let(:http_client) { instance_double(LlmConversation::HttpClient) }
  let(:service) { described_class.new(account:) }
  let(:evaluation_response) do
    {
      "success" => true,
      "data" => {
        "overall_assessment" => "Student demonstrated strong analytical skills and good understanding of the material.",
        "key_moments" => [
          {
            "learning_objective" => "Critical thinking",
            "evidence" => "Student analyzed the problem systematically",
            "message_number" => 3
          }
        ],
        "learning_objectives_evaluation" => [
          {
            "objective" => "Critical thinking",
            "met" => true,
            "score" => 85,
            "explanation" => "Student showed excellent analytical skills"
          },
          {
            "objective" => "Historical context",
            "met" => false,
            "score" => 45,
            "explanation" => "Student needs more practice with historical analysis"
          }
        ],
        "strengths" => [
          "Clear communication",
          "Systematic approach",
          "Good problem-solving skills"
        ],
        "areas_for_improvement" => [
          "Historical context analysis",
          "Evidence citation"
        ],
        "overall_score" => 75
      }
    }
  end

  before do
    allow(LlmConversation::HttpClient).to receive(:new).and_return(http_client)
  end

  describe "#evaluate" do
    it "posts to the evaluate endpoint and returns data" do
      allow(http_client).to receive(:post)
        .with("/conversations/#{conversation_id}/evaluate")
        .and_return(evaluation_response)

      result = service.evaluate(conversation_id:)

      expect(result).to be_a(Hash)
      expect(result["overall_assessment"]).to be_present
      expect(result["overall_score"]).to eq(75)
      expect(result["learning_objectives_evaluation"]).to be_an(Array)
      expect(result["learning_objectives_evaluation"].length).to eq(2)
      expect(result["strengths"]).to be_an(Array)
      expect(result["areas_for_improvement"]).to be_an(Array)
      expect(result["key_moments"]).to be_an(Array)
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { service.evaluate(conversation_id: nil) }.to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:post)
        .and_raise(LlmConversation::Errors::ConversationError, "Internal Server Error")

      expect { service.evaluate(conversation_id:) }.to raise_error(LlmConversation::Errors::ConversationError)
    end
  end
end
