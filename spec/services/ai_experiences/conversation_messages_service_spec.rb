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

describe AiExperiences::ConversationMessagesService do
  let(:user) { user_model }
  let(:conversation_id) { "test-conversation-id" }
  let(:http_client) { instance_double(LlmConversation::HttpClient) }
  let(:service) { described_class.new }

  before do
    allow(LlmConversation::HttpClient).to receive(:new).and_return(http_client)
  end

  describe "#fetch_with_progress" do
    let(:messages_response) do
      {
        "success" => true,
        "data" => [
          { "id" => "msg1", "text" => "User message", "is_llm_message" => false },
          { "id" => "msg2", "text" => "Assistant message", "is_llm_message" => true }
        ]
      }
    end

    let(:conversation_response) do
      {
        "success" => true,
        "data" => {
          "id" => conversation_id,
          "learning_objective_progress" => {
            "objectives" => [
              { "objective" => "Learn basics", "status" => "covered" },
              { "objective" => "Advanced topics", "status" => "" }
            ]
          }
        }
      }
    end

    it "fetches and formats messages" do
      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return(messages_response)
      allow(http_client).to receive(:get)
        .with("/conversations/#{conversation_id}")
        .and_return(conversation_response)

      result = service.fetch_with_progress(conversation_id:, requesting_user: user)

      expect(result[:messages]).to be_an(Array)
      expect(result[:messages].length).to eq(2)
      expect(result[:messages][0][:role]).to eq("User")
      expect(result[:messages][1][:role]).to eq("Assistant")
    end

    it "fetches progress from conversation when not present on messages" do
      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return(messages_response)
      allow(http_client).to receive(:get)
        .with("/conversations/#{conversation_id}")
        .and_return(conversation_response)

      result = service.fetch_with_progress(conversation_id:, requesting_user: user)

      expect(result[:progress]).to be_a(Hash)
      expect(result[:progress][:percentage]).to eq(50)
      expect(result[:progress][:current]).to eq(1)
      expect(result[:progress][:total]).to eq(2)
      expect(result[:progress][:objectives].length).to eq(2)
    end

    it "includes feedback when requesting_user is provided" do
      messages_with_feedback = {
        "success" => true,
        "data" => [
          { "id" => "msg1", "text" => "Hi", "is_llm_message" => false, "feedback" => [] },
          { "id" => "msg2", "text" => "Hello", "is_llm_message" => true, "feedback" => [{ "id" => "fb-1", "vote" => "liked" }] }
        ]
      }

      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return(messages_with_feedback)
      allow(http_client).to receive(:get)
        .with("/conversations/#{conversation_id}")
        .and_return({ "success" => true, "data" => {} })

      result = service.fetch_with_progress(conversation_id:, requesting_user: user)

      expect(result[:messages][0][:feedback]).to eq([])
      expect(result[:messages][1][:feedback].first["vote"]).to eq("liked")
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { service.fetch_with_progress(conversation_id: nil) }
        .to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:get)
        .and_raise(LlmConversation::Errors::ConversationError, "Service unavailable")

      expect { service.fetch_with_progress(conversation_id:, requesting_user: user) }
        .to raise_error(LlmConversation::Errors::ConversationError)
    end
  end

  describe "#extract_progress (via fetch_with_progress)" do
    it "calculates progress correctly" do
      response_with_progress = {
        "success" => true,
        "data" => [
          {
            "id" => "msg1",
            "text" => "Hi",
            "is_llm_message" => true,
            "learning_objective_progress" => {
              "objectives" => [
                { "objective" => "Objective 1", "status" => "covered" },
                { "objective" => "Objective 2", "status" => "" },
                { "objective" => "Objective 3", "status" => "covered" }
              ]
            }
          }
        ]
      }

      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return(response_with_progress)

      result = service.fetch_with_progress(conversation_id:, requesting_user: user)

      expect(result[:progress][:current]).to eq(2)
      expect(result[:progress][:total]).to eq(3)
      expect(result[:progress][:percentage]).to eq(67)
    end

    it "returns nil progress when no progress data" do
      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return({ "success" => true, "data" => [{ "id" => "msg1", "text" => "Hi", "is_llm_message" => false }] })
      allow(http_client).to receive(:get)
        .with("/conversations/#{conversation_id}")
        .and_return({ "success" => true, "data" => {} })

      result = service.fetch_with_progress(conversation_id:, requesting_user: user)

      expect(result[:progress]).to be_nil
    end

    it "handles empty objectives array" do
      response_with_empty_progress = {
        "success" => true,
        "data" => [
          {
            "id" => "msg1",
            "text" => "Hi",
            "is_llm_message" => true,
            "learning_objective_progress" => { "objectives" => [] }
          }
        ]
      }

      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return(response_with_empty_progress)

      result = service.fetch_with_progress(conversation_id:, requesting_user: user)

      expect(result[:progress][:current]).to eq(0)
      expect(result[:progress][:total]).to eq(0)
      expect(result[:progress][:percentage]).to eq(0)
    end
  end
end
